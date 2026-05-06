import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import joblib

np.random.seed(42)
n = 1000

df = pd.DataFrame({
    "files_changed":    np.random.randint(1, 20, n),
    "lines_added":      np.random.randint(0, 500, n),
    "lines_removed":    np.random.randint(0, 300, n),
    "commit_count":     np.random.randint(1, 30, n),
    "commit_frequency": np.random.uniform(0.1, 10.0, n),  # commits per day
})

# Risk label: High if many files changed + many lines, else Medium/Low
def label(row):
    score = (row.files_changed * 2) + (row.lines_added / 50) + (row.lines_removed / 30)
    if score > 30:   return 2  # High
    elif score > 15: return 1  # Medium
    else:            return 0  # Low

df["risk_label"] = df.apply(label, axis=1)

X = df.drop("risk_label", axis=1)
y = df["risk_label"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

print(classification_report(y_test, model.predict(X_test)))

joblib.dump(model, "model.pkl")
print("Model saved to model.pkl")
