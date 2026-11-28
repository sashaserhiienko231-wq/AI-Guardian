import pytest

from app.services.security import analyze_email, analyze_password, analyze_url, validate_public_url


def test_https_url_is_not_automatically_safe():
    result = analyze_url("https://example.com/login")
    assert result["risk_score"] == 0
    assert result["risk_category"] == "Safe"


def test_ip_url_is_high_risk():
    result = analyze_url("http://8.8.8.8/login")
    assert result["risk_score"] >= 40
    assert "IP_HOST" in [item["code"] for item in result["indicators"]]


def test_punycode_and_redirect_are_detected():
    result = analyze_url("https://xn--e1afmkfd.example.com/?destination=https%3A%2F%2Fevil.example")
    assert "PUNYCODE" in [item["code"] for item in result["indicators"]]


def test_invalid_url_rejected():
    import pytest
    with pytest.raises(ValueError):
        analyze_url("javascript:alert(1)")


def test_email_detects_credentials_and_urgency():
    result = analyze_email(
        "Urgent account verification",
        "Immediately send your password to verify your account.",
        "security@example.net",
    )
    assert result["risk_score"] >= 40
    codes = {item["code"] for item in result["indicators"]}
    assert {"URGENT_LANGUAGE", "CREDENTIAL_REQUEST", "ACCOUNT_VERIFICATION"} <= codes


def test_password_never_leaves_local_analysis():
    result = analyze_password("Correct-Horse-Battery-Staple-2026!")
    assert "entropy_bits" in result
    assert result["risk_score"] >= 0


def test_common_password_is_weak():
    result = analyze_password("password")
    assert "COMMON_PASSWORD" in [item["code"] for item in result["indicators"]]


def test_unicode_domain_detected():
    result = analyze_url("https://приклад.укр/login")
    assert "UNICODE_DOMAIN" in [item["code"] for item in result["indicators"]]


def test_unusual_port_detected():
    import pytest
    with pytest.raises(ValueError):
        analyze_url("https://example.com:8443/login")


def test_ssrf_loopback_rejected():
    with pytest.raises(ValueError):
        validate_public_url("http://127.0.0.1/admin")


def test_ssrf_private_network_rejected():
    with pytest.raises(ValueError):
        validate_public_url("http://192.168.1.20/internal")


def test_ssrf_localhost_rejected():
    with pytest.raises(ValueError):
        validate_public_url("http://localhost:8000/health")


def test_url_credentials_rejected():
    with pytest.raises(ValueError):
        validate_public_url("https://user:pass@example.com")


def test_nonstandard_public_port_rejected():
    with pytest.raises(ValueError):
        validate_public_url("https://example.com:8443/login")


@pytest.mark.parametrize(
    "hostname",
    [
        "example.com",
        "api.example.co.uk",
        "xn--e1afmkfd.example",
        "приклад.example",
    ],
)
def test_public_ascii_hostnames_are_accepted(hostname, monkeypatch):
    monkeypatch.setattr(
        "app.services.security.socket.getaddrinfo",
        lambda *args, **kwargs: [(None, None, None, None, ("8.8.8.8", 443))],
    )

    validate_public_url(f"https://{hostname}/")


@pytest.mark.parametrize(
    "hostname",
    [
        "example..com",
        f"{'a' * 64}.example",
        f"{'a' * 63}.{'.'.join(['b' * 63] * 3)}.com",
        "-example.com",
        "example-.com",
        "exa_mple.com",
        "example.c",
        "example.-com",
    ],
)
def test_invalid_ascii_hostnames_are_rejected(hostname):
    with pytest.raises(ValueError):
        validate_public_url(f"https://{hostname}/")


def test_brand_similarity_detected(monkeypatch):
    monkeypatch.delenv("GOOGLE_SAFE_BROWSING_API_KEY", raising=False)
    monkeypatch.delenv("PHISHING_BLOCKLIST_PATH", raising=False)
    result = analyze_url("https://paypa1-secure-login.example.com")
    assert "BRAND_IMPERSONATION" in [item["code"] for item in result["indicators"]]


def test_official_brand_domain_not_flagged(monkeypatch):
    monkeypatch.delenv("GOOGLE_SAFE_BROWSING_API_KEY", raising=False)
    monkeypatch.delenv("PHISHING_BLOCKLIST_PATH", raising=False)
    result = analyze_url("https://accounts.paypal.com/login")
    assert "BRAND_IMPERSONATION" not in [item["code"] for item in result["indicators"]]


def test_local_blocklist_detected(monkeypatch, tmp_path):
    blocklist = tmp_path / "phishing-domains.txt"
    blocklist.write_text("known-phishing.example\n", encoding="utf-8")
    monkeypatch.setenv("PHISHING_BLOCKLIST_PATH", str(blocklist))
    monkeypatch.delenv("GOOGLE_SAFE_BROWSING_API_KEY", raising=False)
    result = analyze_url("https://known-phishing.example/login")
    assert "LOCAL_BLOCKLIST" in [item["code"] for item in result["indicators"]]
