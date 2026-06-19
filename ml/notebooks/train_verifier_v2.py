"""
Train verifier v2 — adds has_evidence and photo_age_minutes features.

New features are appended AFTER all v1 features so that existing code
that doesn't pass them can still fall back safely (predictor defaults them).

Run from the ml/ directory:
    uv run python notebooks/train_verifier_v2.py
"""
from __future__ import annotations

import numpy as np
import pandas as pd
import joblib
from pathlib import Path

from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import OneHotEncoder

from pyod.models.ecod import ECOD

RNG = np.random.default_rng(42)

# ──────────────────────────────────────────────────────────────────────────────
# 1. Synthetic data (same as v1 plus evidence signals)
# ──────────────────────────────────────────────────────────────────────────────

DISTRICTS = {
    "Miraflores":              (-12.121, -77.030),
    "Barranco":                (-12.149, -77.022),
    "San Isidro":              (-12.097, -77.036),
    "Surco":                   (-12.135, -76.994),
    "La Victoria":             (-12.066, -77.030),
    "San Juan de Lurigancho":  (-11.985, -77.006),
    "Callao":                  (-12.056, -77.118),
    "Comas":                   (-11.949, -77.061),
}
INCIDENT_TYPES = ["ROBBERY", "ASSAULT", "THEFT", "VANDALISM", "SUSPICIOUS"]
NAMES = list(DISTRICTS.keys())

FLAG_MAPS = {
    "weapon":  {"none": 0, "knife": 1, "firearm": 2},
    "injured": {"no": 0, "yes": 1},
}


def _jitter(center: float, scale: float = 0.01) -> float:
    return float(center + RNG.normal(0, scale))


def _night_bias() -> np.ndarray:
    w = np.ones(24)
    for h in range(24):
        if h >= 20 or h <= 3:
            w[h] = 3.0
    return w / w.sum()


def make_normal(n: int) -> list[dict]:
    rows = []
    for _ in range(n):
        d = RNG.choice(NAMES)
        lat0, lng0 = DISTRICTS[d]
        has_ev = bool(RNG.random() < 0.70)  # normal: 70% include evidence
        age = float(RNG.uniform(2, 15)) if has_ev else 999.0
        rows.append({
            "incident_type": str(RNG.choice(INCIDENT_TYPES, p=[0.35, 0.20, 0.30, 0.10, 0.05])),
            "lat": _jitter(lat0), "lng": _jitter(lng0),
            "hour": int(RNG.choice(range(24), p=_night_bias())),
            "day_of_week": int(RNG.integers(0, 7)),
            "weapon": str(RNG.choice(["none", "knife", "firearm"], p=[0.70, 0.22, 0.08])),
            "injured": str(RNG.choice(["no", "yes"], p=[0.85, 0.15])),
            "report_count": int(RNG.integers(1, 5)),
            "has_evidence": has_ev,
            "photo_age_minutes": age,
            "is_anomaly": 0,
        })
    return rows


def make_anomalies(n: int) -> list[dict]:
    rows = []
    for _ in range(n):
        d = RNG.choice(NAMES)
        lat0, lng0 = DISTRICTS[d]
        kind = int(RNG.integers(0, 3))
        has_ev = bool(RNG.random() < 0.20)  # suspicious: only 20% have evidence
        age = float(RNG.uniform(120, 999)) if has_ev else 999.0
        if kind == 0:
            row = {
                "incident_type": "VANDALISM", "lat": _jitter(lat0), "lng": _jitter(lng0),
                "hour": int(RNG.choice([12, 13, 14])), "day_of_week": int(RNG.integers(0, 7)),
                "weapon": "firearm", "injured": "yes", "report_count": 1,
            }
        elif kind == 1:
            row = {
                "incident_type": str(RNG.choice(INCIDENT_TYPES)),
                "lat": _jitter(-12.0, 0.6), "lng": _jitter(-77.0, 0.6),
                "hour": int(RNG.integers(0, 24)), "day_of_week": int(RNG.integers(0, 7)),
                "weapon": str(RNG.choice(["none", "knife", "firearm"])),
                "injured": str(RNG.choice(["no", "yes"])),
                "report_count": 1,
            }
        else:
            row = {
                "incident_type": "SUSPICIOUS", "lat": _jitter(lat0), "lng": _jitter(lng0),
                "hour": int(RNG.integers(0, 24)), "day_of_week": int(RNG.integers(0, 7)),
                "weapon": "none", "injured": "no",
                "report_count": int(RNG.integers(40, 80)),
            }
        row["has_evidence"] = has_ev
        row["photo_age_minutes"] = age
        row["is_anomaly"] = 1
        rows.append(row)
    return rows


# ──────────────────────────────────────────────────────────────────────────────
# 2. Feature engineering (v1 features first, then v2 additions)
# ──────────────────────────────────────────────────────────────────────────────

def build_features(
    frame: pd.DataFrame,
    ohe: OneHotEncoder | None = None,
    fit: bool = False,
) -> tuple[pd.DataFrame, OneHotEncoder]:
    f = frame.copy()
    # Cyclic encoding
    f["hour_sin"] = np.sin(2 * np.pi * f["hour"] / 24)
    f["hour_cos"] = np.cos(2 * np.pi * f["hour"] / 24)
    f["dow_sin"]  = np.sin(2 * np.pi * f["day_of_week"] / 7)
    f["dow_cos"]  = np.cos(2 * np.pi * f["day_of_week"] / 7)
    # Ordinal flags
    f["weapon_lvl"]  = f["weapon"].map(FLAG_MAPS["weapon"])
    f["injured_lvl"] = f["injured"].map(FLAG_MAPS["injured"])
    # One-hot for incident type
    if fit:
        ohe = OneHotEncoder(
            categories=[INCIDENT_TYPES], sparse_output=False, handle_unknown="ignore"
        )
        type_arr = ohe.fit_transform(f[["incident_type"]])
    else:
        assert ohe is not None
        type_arr = ohe.transform(f[["incident_type"]])

    type_cols = [f"type_{t}" for t in INCIDENT_TYPES]
    type_df = pd.DataFrame(type_arr, columns=type_cols, index=f.index)

    # v1 numeric columns (order must match v1 for safe ensemble comparison)
    num_cols = [
        "lat", "lng",
        "hour_sin", "hour_cos",
        "dow_sin", "dow_cos",
        "weapon_lvl", "injured_lvl",
        "report_count",
    ]
    X = pd.concat([f[num_cols], type_df], axis=1)

    # v2 additions — appended AFTER all v1 features
    X["has_evidence"]      = f["has_evidence"].astype(float)
    X["photo_age_minutes"] = f["photo_age_minutes"].clip(0, 999)

    return X, ohe  # type: ignore[return-value]


# ──────────────────────────────────────────────────────────────────────────────
# 3. Build dataset and train
# ──────────────────────────────────────────────────────────────────────────────

df = pd.DataFrame(make_normal(2000) + make_anomalies(100))
df = df.sample(frac=1, random_state=42).reset_index(drop=True)
print("Dataset shape:", df.shape)
print("Anomaly rate:", df["is_anomaly"].mean().round(3))

X, ohe = build_features(df, fit=True)
FEATURE_COLUMNS = list(X.columns)
print("Feature columns:", FEATURE_COLUMNS)

CONTAMINATION = 0.05

ecod = ECOD(contamination=CONTAMINATION)
ecod.fit(X.values)

iforest = IsolationForest(n_estimators=200, contamination=CONTAMINATION, random_state=42)
iforest.fit(X.values)

print("ECOD + IsolationForest trained (v2)")

# ──────────────────────────────────────────────────────────────────────────────
# 4. Smoke test on known examples
# ──────────────────────────────────────────────────────────────────────────────

def verify_sample(report: dict, bundle: dict) -> dict:
    row = pd.DataFrame([report])
    X1, _ = build_features(row, ohe=bundle["ohe"], fit=False)
    X1 = X1[bundle["feature_columns"]].values
    ecod_flag = int(bundle["ecod"].predict(X1)[0] == 1)
    if_flag   = int(bundle["iforest"].predict(X1)[0] == -1)
    is_anomaly = bool(ecod_flag and if_flag)
    p_out = float(bundle["ecod"].predict_proba(X1)[0, 1])
    confidence = p_out if is_anomaly else 1.0 - p_out
    return {"is_coherent": not is_anomaly, "confidence": round(confidence, 3)}


# ──────────────────────────────────────────────────────────────────────────────
# 5. Save verifier_v2.joblib (keep v1 untouched)
# ──────────────────────────────────────────────────────────────────────────────

HERE = Path(__file__).parent
ML_ROOT = HERE.parent
MODELS_DIR = ML_ROOT / "src" / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)
ARTIFACT = MODELS_DIR / "verifier_v2.joblib"

bundle = {
    "version": "v2",
    "ecod": ecod,
    "iforest": iforest,
    "ohe": ohe,
    "feature_columns": FEATURE_COLUMNS,
    "incident_types": INCIDENT_TYPES,
    "contamination": CONTAMINATION,
    "ensemble_rule": "AND",
    "flag_maps": FLAG_MAPS,
}
joblib.dump(bundle, ARTIFACT)
print("Saved:", ARTIFACT.resolve())

# Verify load
loaded = joblib.load(ARTIFACT)

sample_ok = {
    "incident_type": "ROBBERY", "lat": -12.121, "lng": -77.030,
    "hour": 22, "day_of_week": 4,
    "weapon": "knife", "injured": "no", "report_count": 2,
    "has_evidence": True, "photo_age_minutes": 8.0,
}
sample_bad = {
    "incident_type": "VANDALISM", "lat": -9.000, "lng": -70.000,
    "hour": 13, "day_of_week": 2,
    "weapon": "firearm", "injured": "yes", "report_count": 1,
    "has_evidence": False, "photo_age_minutes": 999.0,
}
print("Normal  ->", verify_sample(sample_ok, loaded))
print("Anomaly ->", verify_sample(sample_bad, loaded))
print("Done — verifier_v2.joblib ready.")
