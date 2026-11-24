# ML Documentation

`backend/app/ml/train.py` provides a real training pipeline using TF-IDF and logistic
regression. It expects a licensed CSV with `text` and binary `label` columns.

The pipeline creates 70/15/15 train/validation/test separation and reports precision,
recall, F1, and the test confusion matrix. A dataset is not bundled, so no model accuracy
is claimed. The ML model complements, rather than replaces, deterministic findings.
