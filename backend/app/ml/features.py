import math
import re
from ipaddress import ip_address
from urllib.parse import urlparse


SUSPICIOUS_WORDS = (
    "login", "verify", "secure", "account", "update", "bank",
    "wallet", "confirm", "password", "bonus",
)


def extract_url_features(url: str) -> dict[str, float | int]:
    if not url:
        return {}
    parsed = urlparse(url.strip())
    host = (parsed.hostname or "").lower()
    labels = [label for label in host.split(".") if label]
    try:
        host_is_ip = 1 if ip_address(host) else 0
    except ValueError:
        host_is_ip = 0
    return {
        "url_length": len(url),
        "host_length": len(host),
        "path_length": len(parsed.path),
        "subdomain_count": max(0, len(labels) - 2),
        "suspicious_character_count": sum(url.count(char) for char in "@%-_~"),
        "ip_address": host_is_ip,
        "uses_https": int(parsed.scheme.lower() == "https"),
        "punycode": int("xn--" in host),
        "suspicious_word_count": sum(word in url.lower() for word in SUSPICIOUS_WORDS),
        "redirect_parameter": int(bool(re.search(r"(redirect|url|next|dest|continue)=", url, re.I))),
        "query_length": len(parsed.query),
        "digit_ratio": sum(char.isdigit() for char in url) / max(1, len(url)),
    }
