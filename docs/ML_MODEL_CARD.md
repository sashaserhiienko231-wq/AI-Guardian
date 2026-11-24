# ML Model Card

AI Guardian bundles a trained PhiUSIIL URL classifier and does not present it as a
replacement for verified threat analysis.

The training entry point is `backend/app/ml/train.py`. It uses external labeled
data with `text` and binary `label` columns. Metrics include precision, recall,
F1, and confusion matrix values from test data.

URL feature extraction is implemented in `backend/app/ml/features.py`.
ML predictions must remain separate from heuristic findings and must not be
reported as confirmed malware.

## Actual training result

Dataset: PhiUSIIL, UCI ID 967, CC BY 4.0.

- Train rows: 165056
- Validation rows: 35369
- Test rows: 35370
- Precision: 0.986313
- Recall: 0.997479
- F1: 0.991864
- ROC-AUC: 0.996794

Test confusion matrix:

```text
[[14862, 280],
 [   51,20177]]
```

The model is a URL-derived-feature Logistic Regression classifier. It predicts
dataset label 1 as legitimate and 0 as phishing. API output is explicitly marked
probabilistic and is not a verified threat confirmation.

## Known limitations

- The model uses URL structure features, not page reputation or live DNS verdicts.
- Preprocessing must remain identical to `extract_url_features()` at inference.
- Published metrics are dataset-specific and may degrade on other populations.
- Malformed or unknown URLs must not be classified as confirmed phishing.
- Model file: `backend/models/phishing-v1/phishing-model.joblib`
- Model SHA-256: `4c757eab8ea0eb21724d26fc2fd7c0e41d05047612d7a70e4133ce55e9cd08d5`
- Inference reports the model version and SHA-256 in API responses.
