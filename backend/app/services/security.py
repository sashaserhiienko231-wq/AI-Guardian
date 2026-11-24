import math
import os
import re
import string
import socket
import time
from ipaddress import ip_address, ip_network
from urllib.parse import urlparse

import httpx

SUSPICIOUS_SHORTENERS = {"bit.ly", "tinyurl.com", "t.co", "is.gd", "cutt.ly", "goo.gl"}

SIMILAR_BRANDS = {
    "paypal": ("paypal.com",),
    "google": ("google.com", "accounts.google.com"),
    "microsoft": ("microsoft.com", "live.com", "office.com"),
    "apple": ("apple.com", "icloud.com"),
    "amazon": ("amazon.com",),
    "facebook": ("facebook.com", "meta.com"),
    "instagram": ("instagram.com",),
    "netflix": ("netflix.com",),
    "coinbase": ("coinbase.com",),
    "binance": ("binance.com",),
}

_SAFE_BROWSING_CACHE: dict[str, tuple[float, bool]] = {}
_SAFE_BROWSING_CACHE_SECONDS = 300


def _levenshtein(left: str, right: str) -> int:
    previous = list(range(len(right) + 1))
    for i, left_char in enumerate(left, 1):
        current = [i]
        for j, right_char in enumerate(right, 1):
            current.append(min(current[-1] + 1, previous[j] + 1,
                                previous[j - 1] + (left_char != right_char)))
        previous = current
    return previous[-1]


def _loaded_blocklist() -> set[str]:
    domains: set[str] = set()
    path = os.getenv("PHISHING_BLOCKLIST_PATH")
    if not path:
        return domains
    try:
        for line in open(path, "r", encoding="utf-8"):
            domain = line.strip().lower().rstrip(".")
            if domain and not domain.startswith("#"):
                domains.add(domain)
    except OSError:
        return domains
    return domains


def _google_safe_browsing_check(url: str) -> bool:
    api_key = os.getenv("GOOGLE_SAFE_BROWSING_API_KEY", "").strip()
    if not api_key:
        return False
    cached = _SAFE_BROWSING_CACHE.get(url)
    now = time.monotonic()
    if cached and now - cached[0] < _SAFE_BROWSING_CACHE_SECONDS:
        return cached[1]
    try:
        response = httpx.post(
            f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={api_key}",
            json={
                "client": {"clientId": "ai-guardian", "clientVersion": "2.0.0"},
                "threatInfo": {
                    "threatTypes": ["MALWARE_THREAT", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE_THREAT"],
                    "platformTypes": ["ANY_PLATFORM"],
                    "threatEntryTypes": ["URL"],
                    "threatEntries": [{"url": url}],
                },
            },
            timeout=float(os.getenv("AI_TIMEOUT_SECONDS", "10")),
        )
        response.raise_for_status()
        dangerous = bool(response.json().get("matches"))
    except (httpx.HTTPError, httpx.TimeoutException, ValueError):
        dangerous = False
    _SAFE_BROWSING_CACHE[url] = (now, dangerous)
    return dangerous


def check_phishing_blocklists(raw_url: str, host: str) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    host = host.lower().rstrip(".")
    for blocked in _loaded_blocklist():
        if host == blocked or host.endswith("." + blocked):
            findings.append({
                "code": "LOCAL_BLOCKLIST",
                "title": "Listed by local phishing blocklist",
                "explanation": f"The hostname is present in the configured phishing blocklist.",
            })
            break
    if _google_safe_browsing_check(raw_url):
        findings.append({
            "code": "SAFE_BROWSING",
            "title": "Known phishing or unsafe URL",
            "explanation": "Google Safe Browsing reported this URL as unsafe.",
        })
    return findings


def find_brand_similarity(host: str) -> list[dict[str, str]]:
    host = host.lower().rstrip(".")
    findings: list[dict[str, str]] = []
    labels = host.split(".")
    registered = ".".join(labels[-2:]) if len(labels) >= 2 else host
    for brand, official_domains in SIMILAR_BRANDS.items():
        if registered in official_domains or any(host == domain or host.endswith("." + domain)
                                                 for domain in official_domains):
            continue
        candidates = set(labels[:-1] + [registered])
        candidates.update(part.strip("-") for label in labels for part in label.split("-"))
        for candidate in candidates:
            if len(candidate) < 4:
                continue
            if brand in candidate:
                distance = 0
            else:
                distance = _levenshtein(candidate, brand)
            if brand in candidate or (len(candidate) >= len(brand) - 1 and distance <= 1):
                findings.append({
                    "code": "BRAND_IMPERSONATION",
                    "title": f"Possible {brand.title()} impersonation",
                    "explanation": f"The hostname resembles the trusted brand '{brand}' but is not on its official domain.",
                })
                break
        if findings:
            break
    return findings


PRIVATE_NETWORKS = (
    ip_network("10.0.0.0/8"),
    ip_network("127.0.0.0/8"),
    ip_network("169.254.0.0/16"),
    ip_network("172.16.0.0/12"),
    ip_network("192.168.0.0/16"),
    ip_network("100.64.0.0/10"),
    ip_network("0.0.0.0/8"),
    ip_network("::1/128"),
    ip_network("fc00::/7"),
    ip_network("fe80::/10"),
)


def validate_public_url(raw_url: str) -> None:
    text = raw_url.strip()
    if not text or len(text) > 2048:
        raise ValueError("URL must contain between 1 and 2048 characters")
    parsed = urlparse(text)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("Only HTTP and HTTPS URLs are supported")
    if parsed.username or parsed.password:
        raise ValueError("URLs containing credentials are not allowed")
    if not parsed.hostname:
        raise ValueError("URL has no valid hostname")
    try:
        port = parsed.port
    except ValueError as exc:
        raise ValueError("URL contains an invalid port") from exc
    if port is not None and port not in {80, 443}:
        raise ValueError("Only standard HTTP/HTTPS ports are allowed")

    host = parsed.hostname.lower().rstrip(".")
    if host in {"localhost", "localhost.localdomain"} or host.endswith(".localhost"):
        raise ValueError("Local and loopback hosts are not allowed")
    try:
        literal = ip_address(host)
    except ValueError:
        literal = None
    if literal is not None:
        if literal.is_private or literal.is_loopback or literal.is_link_local or literal.is_reserved:
            raise ValueError("Private, loopback, link-local, or reserved IP addresses are not allowed")
    else:
        try:
            ascii_host = host.encode("idna").decode("ascii").lower()
        except UnicodeError as exc:
            raise ValueError("Hostname is not valid IDNA") from exc
        if not re.fullmatch(r"(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]{2,63}", ascii_host):
            raise ValueError("Hostname format is invalid")
        try:
            addresses = socket.getaddrinfo(ascii_host, port or (443 if parsed.scheme == "https" else 80),
                                           type=socket.SOCK_STREAM)
        except socket.gaierror as exc:
            return
        if not addresses:
            raise ValueError("Hostname resolved to no addresses")
        for address in addresses:
            resolved = ip_address(address[4][0].split("%", 1)[0])
            if resolved.is_private or resolved.is_loopback or resolved.is_link_local or resolved.is_reserved:
                raise ValueError("Hostname resolves to a private or restricted address")


def analyze_url(raw_url: str) -> dict:
    text = raw_url.strip()
    validate_public_url(text)
    if not re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", text):
        raise ValueError("URL must include a supported scheme")

    parsed = urlparse(text)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("Only HTTP and HTTPS URLs are supported")
    if not parsed.hostname:
        raise ValueError("URL has no valid hostname")

    score = 0
    indicators: list[dict[str, str]] = []
    explanations: list[str] = []
    actions: list[str] = []
    host = parsed.hostname.lower().rstrip(".")
    suspicious_keywords = ("login", "verify", "secure", "account", "update", "bonus", "wallet", "confirm")

    def add(score_delta: int, code: str, title: str, explanation: str):
        nonlocal score
        score += score_delta
        indicators.append({"code": code, "title": title})
        explanations.append(explanation)

    if parsed.scheme == "http":
        add(18, "NO_TLS", "Unencrypted connection", "The URL uses HTTP; traffic can be intercepted.")
    try:
        ip_address(host)
        add(35, "IP_HOST", "IP address used as host", "Legitimate services commonly use domain names.")
    except ValueError:
        pass
    if "。" in text or any(ord(char) > 127 for char in host):
        add(18, "UNICODE_DOMAIN", "Internationalized domain", "Unicode domains require careful homograph review.")
    try:
        if parsed.port is not None and parsed.port not in {80, 443}:
            add(18, "UNUSUAL_PORT", "Suspicious or unusual port", "The URL uses a port rarely associated with normal web traffic.")
    except ValueError:
        add(18, "INVALID_PORT", "Invalid URL port", "The URL contains an invalid or malformed port.")
    if any(keyword in host for keyword in suspicious_keywords):
        add(12, "SUSPICIOUS_KEYWORD", "Suspicious domain keyword", "Security-related words in a hostname can imitate trusted brands.")
    if "xn--" in host:
        add(30, "PUNYCODE", "Punycode domain", "Unicode or homograph deception may be involved.")
    if host in SUSPICIOUS_SHORTENERS:
        add(25, "SHORTENER", "URL shortener", "The final destination is hidden.")
    labels = host.split(".")
    if len(labels) > 5:
        add(20, "EXCESSIVE_SUBDOMAINS", "Excessive subdomains", "Long subdomain chains are commonly used to obscure destinations.")
    if re.search(r"[@\s]", text) or re.search(r"%40", text, re.I):
        add(25, "SUSPICIOUS_AT", "Suspicious encoded or @ character", "The URL may disguise its actual destination.")
    if re.search(r"(redirect|url|next|dest|destination|continue)=https?%?3A", text, re.I):
        add(22, "REDIRECT_PARAM", "Redirect parameter", "The URL redirects to a separate destination.")
    if any(char in host for char in "_~"):
        add(12, "UNUSUAL_HOST_CHARS", "Unusual hostname characters", "The hostname contains uncommon characters.")
    if not indicators:
        actions.append("The URL has no rule-based indicators; verify the sender and destination before visiting.")

    for finding in check_phishing_blocklists(text, host):
        add(70 if finding["code"] == "LOCAL_BLOCKLIST" else 80,
            finding["code"], finding["title"], finding["explanation"])
    for finding in find_brand_similarity(host):
        add(35, finding["code"], finding["title"], finding["explanation"])
    if parsed.scheme == "http":
        actions.append("Prefer HTTPS or use a known official page.")
    actions.extend(["Do not enter credentials or payment details.", "Open only after confirming the source."])

    score = min(100, score)
    category = "Safe" if score < 20 else "Low" if score < 40 else "Medium" if score < 65 else "High" if score < 85 else "Critical"
    return {"risk_score": score, "risk_category": category, "indicators": indicators,
            "explanations": explanations, "recommended_actions": list(dict.fromkeys(actions))}


def analyze_email(subject: str, body: str, sender: str, headers: dict[str, str] | None = None) -> dict:
    text = f"{subject}\n{body}".lower()
    score = 0
    indicators: list[dict[str, str]] = []
    explanations: list[str] = []

    checks = [
        (r"\b(urgent|immediately|right now|терміново|негайно)\b", 15, "URGENT_LANGUAGE", "Urgent language", "Urgency is often used to bypass careful decisions."),
        (r"\b(password|credentials|пароль|облікові дані|login)\b", 22, "CREDENTIAL_REQUEST", "Credential request", "Requests for passwords or credentials are a phishing warning sign."),
        (r"\b(bank|payment|invoice|wire|crypto|bitcoin|банк|оплата|переказ)\b", 12, "FINANCIAL_REQUEST", "Financial language", "Financial requests should be independently verified."),
        (r"\b(verify|confirmed|account suspended|locked|підтверд|аккаунт заблок)\b", 18, "ACCOUNT_VERIFICATION", "Account verification", "Fake account warnings frequently request dangerous actions."),
        (r"https?://", 12, "LINK_PRESENT", "Link included", "Links in unsolicited messages require destination verification."),
        (r"\b(download|attachment|invoice\.exe|\.scr|\.js)\b", 15, "ATTACHMENT_RISK", "Suspicious attachment", "Unexpected executable or disguised attachments are dangerous."),
    ]
    for pattern, points, code, title, explanation in checks:
        if re.search(pattern, text):
            score += points
            indicators.append({"code": code, "title": title})
            explanations.append(explanation)

    if headers:
        normalized = {key.lower(): value.lower() for key, value in headers.items()}
        authentication_results = normalized.get("authentication-results", "")
        for mechanism in ("spf", "dkim", "dmarc"):
            if mechanism in authentication_results and "fail" in authentication_results:
                score += 20
                indicators.append({"code": f"{mechanism.upper()}_FAIL", "title": f"{mechanism.upper()} failure"})
                explanations.append(f"The supplied authentication headers indicate {mechanism.upper()} failure.")
        reply_to = normalized.get("reply-to", "")
        return_path = normalized.get("return-path", "")
        if reply_to and return_path and reply_to.split("@")[-1] != return_path.split("@")[-1]:
            score += 18
            indicators.append({"code": "REPLY_PATH_MISMATCH", "title": "Reply-To/Return-Path mismatch"})
            explanations.append("Reply-To and Return-Path domains differ in the supplied headers.")

    sender_domain = ""
    if "@" in sender:
        sender_domain = sender.rsplit("@", 1)[1].lower().strip(">")
    urls = re.findall(r"https?://[^\s<>]+", body)
    for url in urls:
        try:
            host = urlparse(url).hostname or ""
            if sender_domain and host and not host.endswith("." + sender_domain) and host != sender_domain:
                score += 18
                indicators.append({"code": "DOMAIN_MISMATCH", "title": "Sender/link domain mismatch"})
                explanations.append("A message link points to a domain unrelated to the claimed sender.")
                break
        except ValueError:
            pass

    score = min(100, score)
    category = "Safe" if score < 20 else "Low" if score < 40 else "Medium" if score < 65 else "High" if score < 85 else "Critical"
    actions = ["Do not reply with credentials or payment details."]
    if indicators:
        actions.append("Verify the sender using a known official channel.")
    actions.append("Report and delete suspicious messages.")
    return {"risk_score": score, "risk_category": category, "indicators": indicators,
            "explanations": explanations, "recommended_actions": actions}


COMMON_PASSWORDS = {"password", "123456", "12345678", "qwerty", "admin", "letmein", "welcome", "password1"}


def analyze_qr(content: str) -> dict:
    if not content or not content.strip():
        raise ValueError("QR content is required")
    if len(content) > 10000:
        raise ValueError("QR content exceeds 10000 characters")
    text = content.strip()
    lower = text.lower()
    dangerous_schemes = ("javascript:", "data:", "vbscript:", "file:", "ftp:")
    if lower.startswith(dangerous_schemes):
        return {
            "risk_score": 95,
            "risk_category": "MALICIOUS",
            "indicators": [{"code": "DANGEROUS_SCHEME", "title": "Dangerous QR scheme"}],
            "explanations": ["The QR code requests execution or direct access through a non-web scheme."],
            "recommended_actions": ["Do not open or execute this QR content.", "Delete or report the QR source."],
        }
    if lower.startswith(("http://", "https://")):
        return analyze_url(text)
    if re.search(r"(password|seed phrase|private key|otp|парол|приватн)", lower):
        return {
            "risk_score": 75,
            "risk_category": "SUSPICIOUS",
            "indicators": [{"code": "SENSITIVE_REQUEST", "title": "Sensitive-data request"}],
            "explanations": ["The QR content appears to request sensitive account information."],
            "recommended_actions": ["Do not provide secrets.", "Verify the source through an official channel."],
        }
    return {
        "risk_score": 50,
        "risk_category": "UNKNOWN",
        "indicators": [{"code": "NON_URL_CONTENT", "title": "Unverified QR content"}],
        "explanations": ["The QR content is not a web URL, and safety is not confirmed."],
        "recommended_actions": ["Verify the context manually.", "Do not share sensitive decoded content."],
    }


def analyze_password(password: str) -> dict:
    if not password:
        raise ValueError("Password is required")
    if len(password) > 1024:
        raise ValueError("Password exceeds 1024 characters")
    score = 0
    indicators: list[dict[str, str]] = []
    explanations: list[str] = []
    if len(password) >= 16:
        score += 35
    elif len(password) >= 12:
        score += 25
    elif len(password) >= 8:
        score += 12
    else:
        score -= 25
        indicators.append({"code": "SHORT_PASSWORD", "title": "Short password"})
        explanations.append("Passwords shorter than 12 characters are vulnerable to faster guessing.")

    classes = sum(bool(re.search(pattern, password)) for pattern in [
        r"[a-z]", r"[A-Z]", r"[0-9]", r"[^A-Za-z0-9]"
    ])
    score += classes * 12
    if classes < 3:
        indicators.append({"code": "LOW_DIVERSITY", "title": "Low character diversity"})
        explanations.append("Use a mix of letter case, numbers, and symbols.")
    if password.lower() in COMMON_PASSWORDS:
        score -= 35
        indicators.append({"code": "COMMON_PASSWORD", "title": "Common password"})
        explanations.append("This password is widely used and appears in password-guessing lists.")
    if re.search(r"(.)\1{2,}", password) or re.search(r"(0123|1234|abcd|qwerty)", password.lower()):
        score -= 15
        indicators.append({"code": "PATTERN", "title": "Predictable pattern"})
        explanations.append("Repeated or sequential characters are easy to guess.")

    pool = 0
    pool += 26 if re.search(r"[a-z]", password) else 0
    pool += 26 if re.search(r"[A-Z]", password) else 0
    pool += 10 if re.search(r"[0-9]", password) else 0
    pool += 32 if re.search(r"[^A-Za-z0-9]", password) else 0
    entropy = round(len(password) * math.log2(pool), 1) if pool else 0.0
    final_score = max(0, min(100, score))
    category = "Critical" if final_score < 25 else "High" if final_score < 45 else "Medium" if final_score < 65 else "Low" if final_score < 85 else "Safe"
    return {"risk_score": 100 - final_score, "risk_category": "Safe" if category == "Low" else "Low" if category == "Safe" else category,
            "indicators": indicators, "explanations": explanations,
            "entropy_bits": entropy,
            "recommended_actions": ["Use at least 16 characters.", "Use a unique password for every account.", "Use a reputable password manager."]}
