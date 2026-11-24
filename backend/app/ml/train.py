"""Train a URL or text phishing classifier on an external labeled dataset."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from app.ml.features import extract_url_features


def train(dataset: Path, output: Path) -> dict:
    if not dataset.exists():
        raise FileNotFoundError(f"No dataset at {dataset}")

    frame = pd.read_csv(dataset)
    columns = {name.lower(): name for name in frame.columns}
    label_column = columns.get("label") or columns.get("class") or columns.get("target")
    text_column = columns.get("url") or columns.get("text")
    if not label_column:
        raise ValueError("Dataset must contain a label, class, or target column")
    if not text_column:
        raise ValueError("Dataset must contain a URL or text column")

    frame = frame.dropna(subset=[text_column, label_column])
    labels = set(frame[label_column].astype(str))
    if labels not in ({"0", "1"}, {0, 1}):
        raise ValueError("Labels must be binary 0 and 1")
    y = frame[label_column].astype(int)

    if text_column.lower() == "url":
        x = pd.DataFrame([
            extract_url_features(url)
            for url in frame[text_column].astype(str)
        ])
    else:
        x = frame[text_column].astype(str)

    x_train, x_temp, y_train, y_temp = train_test_split(
        x, y, test_size=0.30, random_state=42, stratify=y
    )
    x_validation, x_test, y_validation, y_test = train_test_split(
        x_temp, y_temp, test_size=0.50, random_state=42, stratify=y_temp
    )

    if text_column.lower() == "url":
        model = Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
            ("classifier", LogisticRegression(
                max_iter=1000,
                class_weight="balanced",
                random_state=42,
            )),
        ])
    else:
        model = Pipeline([
            ("tfidf", TfidfVectorizer(max_features=50_000, ngram_range=(1, 2))),
            ("classifier", LogisticRegression(
                max_iter=1000,
                class_weight="balanced",
                random_state=42,
            )),
        ])

    model.fit(x_train, y_train)
    validation_predictions = model.predict(x_validation)
    test_predictions = model.predict(x_test)
    test_probabilities = model.predict_proba(x_test)[:, 1]

    metrics = {
        "precision": float(precision_score(y_test, test_predictions, zero_division=0)),
        "recall": float(recall_score(y_test, test_predictions, zero_division=0)),
        "f1": float(f1_score(y_test, test_predictions, zero_division=0)),
        "roc_auc": float(roc_auc_score(y_test, test_probabilities)),
        "confusion_matrix": confusion_matrix(y_test, test_predictions).tolist(),
        "validation_confusion_matrix": confusion_matrix(
            y_validation, validation_predictions
        ).tolist(),
        "train_rows": len(x_train),
        "validation_rows": len(x_validation),
        "test_rows": len(x_test),
        "class_counts": y.value_counts().sort_index().astype(int).to_dict(),
        "label_semantics": "Dataset label 1=legitimate, 0=phishing.",
        "feature_source": "URL-derived features" if text_column.lower() == "url" else "TF-IDF text",
    }

    output.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, output / "phishing-model.joblib")
    (output / "metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )
    return metrics


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("models/phishing-v1"))
    args = parser.parse_args()
    print(json.dumps(train(args.dataset, args.output), indent=2))
