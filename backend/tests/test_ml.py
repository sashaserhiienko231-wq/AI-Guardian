from app.ml.features import extract_url_features
from app.ml.inference import MlUrlClassifier
from pathlib import Path


def test_url_feature_extraction_ip():
    features = extract_url_features("http://192.168.1.10/login?redirect=https://evil.example")
    assert features["ip_address"] == 1
    assert features["uses_https"] == 0
    assert features["redirect_parameter"] == 1


def test_url_feature_extraction_punycode():
    features = extract_url_features("https://xn--example-domain.example/login")
    assert features["punycode"] == 1
    assert features["suspicious_word_count"] >= 1


def test_trained_model_loads_and_reports_integrity():
    model_path = Path(__file__).resolve().parents[1] / "models" / "phishing-v1" / "phishing-model.joblib"
    assert model_path.exists()
    classifier = MlUrlClassifier(model_path)
    result = classifier.predict("https://example.com/login")
    assert result["prediction"] in {"LEGITIMATE", "PHISHING"}
    assert result["verified_threat"] is False
    assert len(result["model_sha256"]) == 64
    assert result["model_version"] == "phiusiil-v1"
