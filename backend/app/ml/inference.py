from pathlib import Path
import os

import joblib
import pandas as pd
import hashlib

from app.ml.features import extract_url_features
from app.services.security import validate_public_url


class MlUrlClassifier:
    def __init__(self, model_path: Path) -> None:
        if not model_path.exists():
            raise FileNotFoundError(f"ML model not found: {model_path}")
        self.model = joblib.load(model_path)
        self.model_path = model_path
        self.model_version = "phiusiil-v1"
        self.model_sha256 = hashlib.sha256(model_path.read_bytes()).hexdigest()

    def predict(self, url: str) -> dict:
        if not isinstance(url, str) or not url.strip():
            raise ValueError("URL is required")
        if len(url) > 2048:
            raise ValueError("URL exceeds 2048 characters")
        validate_public_url(url)
        frame = pd.DataFrame([extract_url_features(url)])
        probability_legitimate = float(self.model.predict_proba(frame)[0][1])
        phishing_probability = 1.0 - probability_legitimate
        predicted_label = int(self.model.predict(frame)[0])
        return {
            "prediction": "LEGITIMATE" if predicted_label == 1 else "PHISHING",
            "phishing_probability": round(phishing_probability, 6),
            "legitimate_probability": round(probability_legitimate, 6),
            "confidence": round(max(phishing_probability, probability_legitimate), 6),
            "verified_threat": False,
            "model_version": self.model_version,
            "model_sha256": self.model_sha256,
        }


def load_configured_classifier() -> MlUrlClassifier | None:
    configured = os.getenv("ML_MODEL_PATH")
    path = Path(configured) if configured else (
        Path(__file__).resolve().parents[2] / "models" / "phishing-v1" / "phishing-model.joblib"
    )
    return MlUrlClassifier(path) if path.exists() else None
