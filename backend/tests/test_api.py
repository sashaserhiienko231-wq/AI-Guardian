from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_url_scan_and_history():
    scan = client.post("/api/v1/scanner/url", json={"url": "https://example.com"})
    assert scan.status_code == 200
    scan_id = scan.json()["id"]
    detail = client.get(f"/api/v1/history/{scan_id}")
    assert detail.status_code == 200
    assert detail.json()["scan_type"] == "url"


def test_invalid_url():
    response = client.post("/api/v1/scanner/url", json={"url": "javascript:alert(1)"})
    assert response.status_code == 422




def test_delete_history():
    scan = client.post("/api/v1/scanner/qr", json={"content": "Plain text"})
    scan_id = scan.json()["id"]
    deleted = client.delete(f"/api/v1/history/{scan_id}")
    assert deleted.status_code == 204
    assert client.get(f"/api/v1/history/{scan_id}").status_code == 404


def test_unknown_qr_is_not_safe():
    response = client.post("/api/v1/scanner/qr", json={"content": "Plain text"})
    assert response.status_code == 200
    assert response.json()["risk_category"] == "UNKNOWN"
    assert "not confirmed" in " ".join(response.json()["explanations"]).lower()


def test_dangerous_qr_scheme_is_not_safe():
    response = client.post("/api/v1/scanner/qr", json={"content": "javascript:alert(1)"})
    assert response.status_code == 200
    assert response.json()["risk_category"] in {"SUSPICIOUS", "MALICIOUS"}


def test_history_csv_export():
    response = client.get("/api/v1/history/export?format=csv")
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/csv")
    assert "scan_type" in response.text


def test_history_search_and_sort():
    response = client.get("/api/v1/history?limit=10&sort=risk_high")
    assert response.status_code == 200
    assert "items" in response.json()


def test_url_scan_includes_ml_disclosure():
    response = client.post("/api/v1/scanner/url", json={"url": "https://example.com/login"})
    assert response.status_code == 200
    assert "ml_prediction" in response.json()
    assert "ml_disclosure" in response.json()


def test_ml_url_endpoint_returns_probability():
    response = client.post("/api/v1/scanner/url/ml", json={"url": "https://example.com/login"})
    assert response.status_code == 200
    assert "phishing_probability" in response.json()["ml_prediction"]


def test_history_requires_token_when_configured(monkeypatch):
    monkeypatch.setenv("API_AUTH_TOKEN", "audit-test-token")
    unauthenticated = client.get("/api/v1/history")
    assert unauthenticated.status_code == 401
    authenticated = client.get(
        "/api/v1/history",
        headers={"Authorization": "Bearer audit-test-token"},
    )
    assert authenticated.status_code == 200


def test_ai_provider_failure_is_handled(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "ollama")
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://127.0.0.1:1")
    monkeypatch.setenv("AI_TIMEOUT_SECONDS", "0.2")
    response = client.post("/api/v1/assistant/chat", json={"message": "Explain phishing"})
    assert response.status_code == 503
    assert "provider" not in response.json()


def test_ai_assistant_rate_limit(monkeypatch):
    from app.api.v1.routes import _assistant_requests
    _assistant_requests.clear()
    monkeypatch.setenv("AI_PROVIDER", "local")
    monkeypatch.setenv("AI_RATE_LIMIT_PER_MINUTE", "1")
    first = client.post("/api/v1/assistant/chat", json={"message": "Explain phishing"})
    second = client.post("/api/v1/assistant/chat", json={"message": "Explain URL safety"})
    assert first.status_code == 200
    assert second.status_code == 429


def test_password_scan_is_not_saved():
    response = client.post(
        "/api/v1/scanner/password",
        json={"password": "Never-Transmit-This-Password-2026"},
    )
    assert response.status_code == 404


def test_openai_missing_key_is_reported(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "openai")
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    response = client.post("/api/v1/assistant/chat", json={"message": "Explain phishing"})
    assert response.status_code == 503


def test_production_mode_fails_closed_without_token(monkeypatch):
    monkeypatch.setenv("API_PRODUCTION", "true")
    monkeypatch.delenv("API_AUTH_TOKEN", raising=False)
    response = client.get("/api/v1/history")
    assert response.status_code == 503


def test_production_mode_rejects_wrong_token(monkeypatch):
    monkeypatch.setenv("API_PRODUCTION", "true")
    monkeypatch.setenv("API_AUTH_TOKEN", "correct-token")
    response = client.get("/api/v1/history", headers={"Authorization": "Bearer wrong-token"})
    assert response.status_code == 401


def test_production_mode_accepts_correct_token(monkeypatch):
    monkeypatch.setenv("API_PRODUCTION", "true")
    monkeypatch.setenv("API_AUTH_TOKEN", "correct-token")
    response = client.get("/api/v1/history", headers={"Authorization": "Bearer correct-token"})
    assert response.status_code == 200


def test_development_mode_allows_guest_history(monkeypatch):
    monkeypatch.setenv("API_PRODUCTION", "false")
    monkeypatch.delenv("API_AUTH_TOKEN", raising=False)
    response = client.get("/api/v1/history")
    assert response.status_code == 200


def test_root_health_and_ready():
    assert client.get("/health").status_code == 200
    assert client.get("/ready").status_code == 200


def test_versioned_ready():
    response = client.get("/api/v1/ready")
    assert response.status_code == 200
    assert "components" in response.json()


def test_assistant_provider_status():
    response = client.get("/api/v1/assistant/providers")
    assert response.status_code == 200
    assert "active_provider" in response.json()


def test_password_endpoint_not_available():
    response = client.post("/api/v1/scanner/password", json={"password": "test-password"})
    assert response.status_code == 404
