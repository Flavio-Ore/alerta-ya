"""
Train verifier v3 — fixes the incident-type enum mismatch and adds a
photo_trusted feature.

Bug fixed: v1/v2 trained against a made-up enum
[ROBBERY, ASSAULT, THEFT, VANDALISM, SUSPICIOUS] that never matched the real
Prisma `IncidentType` enum [ROBBERY, ACCIDENT, HARASSMENT, EXTORTION,
SUSPICIOUS]. In production, ACCIDENT/HARASSMENT/EXTORTION reports always hit
OneHotEncoder's handle_unknown='ignore' path and got an all-zero one-hot
vector — the model never actually saw a meaningful type signal for 3 of 5
production incident types.

New feature: photo_trusted, derived from the client-asserted photo_source
('exif' | 'device_clock' | None) that api/ now forwards (evidence-authenticity
S3). Appended AFTER all v2 features, using the exact same additive
feature_columns trick that made has_evidence/photo_age_minutes backward-safe
in v2 — v2 bundles keep loading unmodified because VerifierPredictor selects
`feature_columns` from the bundle itself. photo_trusted is informational only:
it shifts the anomaly SCORE like any other feature, it is never read as a
standalone hard gate anywhere in the pipeline.

Run from the ml/ directory:
    uv run python notebooks/train_verifier_v3.py
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
# 1. Synthetic data — real Prisma IncidentType enum + photo provenance
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
# Matches schema.prisma IncidentType — the v1/v2 enum was WRONG (never matched prod).
INCIDENT_TYPES = ["ROBBERY", "ACCIDENT", "HARASSMENT", "EXTORTION", "SUSPICIOUS"]
NAMES = list(DISTRICTS.keys())

FLAG_MAPS = {
    "weapon":  {"none": 0, "knife": 1, "firearm": 2},
    "injured": {"no": 0, "yes": 1},
}

# Class balance for the 5 real incident types.
CLASS_PROBS = [0.30, 0.20, 0.20, 0.10, 0.20]  # ROBBERY, ACCIDENT, HARASSMENT, EXTORTION, SUSPICIOUS

# Per-type weapon/injured correlations (synthetic taxonomy defaults):
#   ROBBERY    -> weapon likely (knife/firearm), injured sometimes
#   ACCIDENT   -> injured likely, no weapon
#   EXTORTION  -> threat/weapon implied, injured rare
#   HARASSMENT -> no weapon, injured rare
#   SUSPICIOUS -> no weapon, no injured (low signal)
# weapon_p order = [none, knife, firearm]; injured_p order = [no, yes].
TYPE_PROFILES: dict[str, dict[str, list[float]]] = {
    "ROBBERY":    {"weapon_p": [0.30, 0.35, 0.35], "injured_p": [0.75, 0.25]},
    "ACCIDENT":   {"weapon_p": [1.00, 0.00, 0.00], "injured_p": [0.30, 0.70]},
    "EXTORTION":  {"weapon_p": [0.25, 0.35, 0.40], "injured_p": [0.90, 0.10]},
    "HARASSMENT": {"weapon_p": [1.00, 0.00, 0.00], "injured_p": [0.92, 0.08]},
    "SUSPICIOUS": {"weapon_p": [1.00, 0.00, 0.00], "injured_p": [1.00, 0.00]},
}


def _jitter(center: float, scale: float = 0.01) -> float:
    return float(center + RNG.normal(0, scale))


def _night_bias() -> np.ndarray:
    w = np.ones(24)
    for h in range(24):
        if h >= 20 or h <= 3:
            w[h] = 3.0
    return w / w.sum()


def _photo_provenance(has_ev: bool, fresh_low: float, fresh_high: float, exif_p: float) -> tuple[str | None, float]:
    """Synthesize (photo_source, photo_age_minutes) mirroring the api boundary fix (S3):
    only photoSource=='exif' is trusted with a real age; device_clock/None -> 999 sentinel,
    exactly like the untrusted path in create-report.usecase.ts."""
    if not has_ev:
        return None, 999.0
    source = str(RNG.choice(["exif", "device_clock"], p=[exif_p, 1 - exif_p]))
    if source == "exif":
        return source, float(RNG.uniform(fresh_low, fresh_high))
    return source, 999.0


def make_normal(n: int) -> list[dict]:
    rows = []
    for _ in range(n):
        d = RNG.choice(NAMES)
        lat0, lng0 = DISTRICTS[d]
        incident_type = str(RNG.choice(INCIDENT_TYPES, p=CLASS_PROBS))
        profile = TYPE_PROFILES[incident_type]
        has_ev = bool(RNG.random() < 0.70)  # normal: 70% include evidence
        photo_source, age = _photo_provenance(has_ev, fresh_low=2, fresh_high=15, exif_p=0.75)
        rows.append({
            "incident_type": incident_type,
            "lat": _jitter(lat0), "lng": _jitter(lng0),
            "hour": int(RNG.choice(range(24), p=_night_bias())),
            "day_of_week": int(RNG.integers(0, 7)),
            "weapon": str(RNG.choice(["none", "knife", "firearm"], p=profile["weapon_p"])),
            "injured": str(RNG.choice(["no", "yes"], p=profile["injured_p"])),
            "report_count": int(RNG.integers(1, 5)),
            "has_evidence": has_ev,
            "photo_source": photo_source,
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
        # anomalies skew toward untrusted/absent provenance (exif_p lower than normal)
        photo_source, age = _photo_provenance(has_ev, fresh_low=120, fresh_high=999, exif_p=0.40)
        if kind == 0:
            # odd midday hour + firearm+injured guaranteed together, regardless of type profile
            row = {
                "incident_type": str(RNG.choice(INCIDENT_TYPES)),
                "lat": _jitter(lat0), "lng": _jitter(lng0),
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
        row["photo_source"] = photo_source
        row["photo_age_minutes"] = age
        row["is_anomaly"] = 1
        rows.append(row)
    return rows


# ──────────────────────────────────────────────────────────────────────────────
# 2. Feature engineering (v1/v2 features first, then v3 additions)
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
    # One-hot for incident type (real Prisma enum)
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

    # v1 numeric columns (order must match v1/v2 for a safe ensemble comparison)
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

    # v3 addition — appended AFTER all v2 features (same additive convention).
    # photo_trusted: 1.0 only when photo_source == 'exif' (client-asserted, see
    # discovery "photoSource trust is client-asserted"). It is a FEATURE, never
    # a hard gate — VerifierPredictor.verify() always returns is_coherent from
    # the ensemble AND rule, this column only shifts the anomaly score.
    X["photo_trusted"] = (f["photo_source"] == "exif").astype(float)

    return X, ohe  # type: ignore[return-value]


# ──────────────────────────────────────────────────────────────────────────────
# 3. Build dataset and train
# ──────────────────────────────────────────────────────────────────────────────

df = pd.DataFrame(make_normal(2000) + make_anomalies(100))
df = df.sample(frac=1, random_state=42).reset_index(drop=True)
print("Dataset shape:", df.shape)
print("Anomaly rate:", df["is_anomaly"].mean().round(3))
print("Incident type distribution:\n", df["incident_type"].value_counts())

X, ohe = build_features(df, fit=True)
FEATURE_COLUMNS = list(X.columns)
print("Feature columns:", FEATURE_COLUMNS)

CONTAMINATION = 0.05

ecod = ECOD(contamination=CONTAMINATION)
ecod.fit(X.values)

iforest = IsolationForest(n_estimators=200, contamination=CONTAMINATION, random_state=42)
iforest.fit(X.values)

print("ECOD + IsolationForest trained (v3)")

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
# 5. Save verifier_v3.joblib (keep v2 untouched)
# ──────────────────────────────────────────────────────────────────────────────

HERE = Path(__file__).parent
ML_ROOT = HERE.parent
MODELS_DIR = ML_ROOT / "src" / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)
ARTIFACT = MODELS_DIR / "verifier_v3.joblib"

bundle = {
    "version": "v3",
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
    "has_evidence": True, "photo_source": "exif", "photo_age_minutes": 8.0,
}
sample_bad = {
    "incident_type": "HARASSMENT", "lat": -9.000, "lng": -70.000,
    "hour": 13, "day_of_week": 2,
    "weapon": "firearm", "injured": "yes", "report_count": 1,
    "has_evidence": False, "photo_source": None, "photo_age_minutes": 999.0,
}
print("Normal  ->", verify_sample(sample_ok, loaded))
print("Anomaly ->", verify_sample(sample_bad, loaded))

# All 5 real incident types must produce a non-zero one-hot column — this is
# the exact bug being fixed (ACCIDENT/HARASSMENT/EXTORTION were always
# all-zero under the old wrong enum).
for t in INCIDENT_TYPES:
    row, _ = build_features(pd.DataFrame([{
        "incident_type": t, "lat": -12.1, "lng": -77.0, "hour": 10, "day_of_week": 1,
        "weapon": "none", "injured": "no", "report_count": 1,
        "has_evidence": False, "photo_source": None, "photo_age_minutes": 999.0,
    }]), ohe=loaded["ohe"], fit=False)
    assert row[f"type_{t}"].iloc[0] == 1.0, f"type_{t} one-hot did not fire"
print("All 5 real incident types produce a non-zero one-hot column — OK")

print("Done — verifier_v3.joblib ready.")
