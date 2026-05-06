from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

app = FastAPI()
model = joblib.load("model.pkl")

LABELS = {0: "Low", 1: "Medium", 2: "High"}

class CommitFeatures(BaseModel):
    files_changed:    int
    lines_added:      int
    lines_removed:    int
    commit_count:     int
    commit_frequency: float = 1.0

@app.post("/predict")
def predict(features: CommitFeatures):
    X = np.array([[
        features.files_changed,
        features.lines_added,
        features.lines_removed,
        features.commit_count,
        features.commit_frequency
    ]])

    prediction = model.predict(X)[0]
    probabilities = model.predict_proba(X)[0]
    confidence = round(float(probabilities[prediction]), 2)
    risk_score = round(float(np.dot(probabilities, [0.0, 0.5, 1.0])), 2)

    return {
        "risk_score": risk_score,
        "risk_level": LABELS[prediction],
        "confidence": confidence
    }

@app.get("/health")
def health():
    return {"status": "ok"}
