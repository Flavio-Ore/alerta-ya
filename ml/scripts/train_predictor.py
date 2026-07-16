"""
Entrena el RiskPredictor (XGBoost Poisson) y exporta src/models/predictor_v1.joblib.

Replica notebooks/02_predictor_training.ipynb de forma ejecutable (headless), y
AGREGA lo que el notebook no persistía: una tabla de lags de serving por
(zone_id, hora). Sin ella el endpoint no puede reconstruir las lag features en
tiempo de request — el notebook las pasaba a mano solo para demostrar el flujo.

Datos: SINTÉTICOS con señal aprendible (hotspots espaciales, sesgo nocturno y de
fin de semana). Reproducible (semilla fija). Migrar a reportes reales es el
siguiente paso del roadmap, sin cambiar la arquitectura del modelo.

Uso:
    uv run python scripts/train_predictor.py
"""
from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.metrics import mean_absolute_error, mean_poisson_deviance, mean_squared_error

RNG = np.random.default_rng(7)

# ── 1. Incidentes crudos sintéticos ──────────────────────────────────────────
N_DAYS = 90
START = pd.Timestamp("2026-01-01")
N_INCIDENTS = 9000

# Hotspots: (lat, lng, peso_relativo, nombre). Más peso = más crimen concentrado.
HOTSPOTS = [
    (-12.066, -77.030, 3.0, "La Victoria"),
    (-11.985, -77.006, 2.5, "San Juan de Lurigancho"),
    (-12.121, -77.030, 1.5, "Miraflores"),
    (-12.056, -77.118, 2.0, "Callao"),
    (-11.949, -77.061, 1.8, "Comas"),
    (-12.135, -76.994, 1.0, "Surco"),
]
INCIDENT_TYPES = ["ROBBERY", "ASSAULT", "THEFT", "VANDALISM"]

# Grilla espacial. En producción el tile DEBE alinearse con el threshold engine
# del API (~0.003° ≈ 330m). Acá 0.03 (~3.3km) para una grilla sintética manejable.
TILE = 0.03
LAT_MIN, LNG_MIN = -12.30, -77.20

FEATURES = [
    "zone_code", "zone_lat", "zone_lng",
    "hour_sin", "hour_cos", "dow_sin", "dow_cos", "is_weekend",
    "inc_last_24h", "inc_last_7d", "inc_same_hour_7d", "inc_adj_24h",
]
LAG_COLS = ["inc_last_24h", "inc_last_7d", "inc_same_hour_7d", "inc_adj_24h"]
TARGET = "count"


def _hour_weights() -> np.ndarray:
    w = np.ones(24)
    for h in range(24):
        if h >= 20 or h <= 3:
            w[h] = 3.0
        elif 4 <= h <= 9:
            w[h] = 0.5
    return w / w.sum()


def _dow_weights() -> np.ndarray:
    # 0=lunes ... 6=domingo; viernes/sábado más peligrosos.
    w = np.array([1.0, 1.0, 1.0, 1.2, 1.8, 2.0, 1.4])
    return w / w.sum()


def _to_zone(lat: float, lng: float) -> tuple[int, int]:
    return int(np.floor((lat - LAT_MIN) / TILE)), int(np.floor((lng - LNG_MIN) / TILE))


def build_raw() -> pd.DataFrame:
    hw, dw = _hour_weights(), _dow_weights()
    hot_p = np.array([w for *_, w, _ in HOTSPOTS])
    hot_p = hot_p / hot_p.sum()
    day_dows = np.array([(START + pd.Timedelta(days=d)).dayofweek for d in range(N_DAYS)])
    day_p = dw[day_dows]
    day_p = day_p / day_p.sum()

    rows = []
    for _ in range(N_INCIDENTS):
        hi = int(RNG.choice(len(HOTSPOTS), p=hot_p))
        lat0, lng0, _, _ = HOTSPOTS[hi]
        d = int(RNG.choice(N_DAYS, p=day_p))
        ts_day = (START + pd.Timedelta(days=d)).normalize()
        rows.append({
            "date": ts_day,
            "hour": int(RNG.choice(range(24), p=hw)),
            "lat": float(lat0 + RNG.normal(0, 0.004)),
            "lng": float(lng0 + RNG.normal(0, 0.004)),
            "incident_type": str(RNG.choice(INCIDENT_TYPES)),
        })
    raw = pd.DataFrame(rows)
    gi_gj = raw.apply(lambda r: pd.Series(_to_zone(r["lat"], r["lng"])), axis=1)
    raw[["gi", "gj"]] = gi_gj
    raw["zone_id"] = raw["gi"].astype(str) + "_" + raw["gj"].astype(str)
    raw["zone_lat"] = LAT_MIN + (raw["gi"] + 0.5) * TILE
    raw["zone_lng"] = LNG_MIN + (raw["gj"] + 0.5) * TILE
    return raw


def build_panel(raw: pd.DataFrame) -> pd.DataFrame:
    zones = raw[["zone_id", "gi", "gj", "zone_lat", "zone_lng"]].drop_duplicates()
    dates = pd.date_range(START, periods=N_DAYS, freq="D")
    grid = (
        zones.assign(key=1)
        .merge(pd.DataFrame({"date": dates, "key": 1}), on="key")
        .merge(pd.DataFrame({"hour": list(range(24)), "key": 1}), on="key")
        .drop(columns="key")
    )
    counts = raw.groupby(["zone_id", "date", "hour"]).size().rename("count").reset_index()
    panel = grid.merge(counts, on=["zone_id", "date", "hour"], how="left")
    panel["count"] = panel["count"].fillna(0).astype(int)
    panel["ts"] = panel["date"] + pd.to_timedelta(panel["hour"], unit="h")
    panel["day_of_week"] = panel["ts"].dt.dayofweek
    return panel.sort_values(["zone_id", "ts"]).reset_index(drop=True)


def add_features(panel: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    panel["hour_sin"] = np.sin(2 * np.pi * panel["hour"] / 24)
    panel["hour_cos"] = np.cos(2 * np.pi * panel["hour"] / 24)
    panel["dow_sin"] = np.sin(2 * np.pi * panel["day_of_week"] / 7)
    panel["dow_cos"] = np.cos(2 * np.pi * panel["day_of_week"] / 7)
    panel["is_weekend"] = (panel["day_of_week"] >= 5).astype(int)

    # Lags por zona. shift(1) excluye el bin actual → sin fuga de datos.
    g = panel.groupby("zone_id", group_keys=False)
    panel["inc_last_24h"] = g["count"].apply(lambda s: s.shift(1).rolling(24, min_periods=1).sum())
    panel["inc_last_7d"] = g["count"].apply(lambda s: s.shift(1).rolling(24 * 7, min_periods=1).sum())
    panel["inc_same_hour_7d"] = (
        panel.groupby(["zone_id", "hour"], group_keys=False)["count"]
        .apply(lambda s: s.shift(1).rolling(7, min_periods=1).mean())
    )

    # Vecinos: tiles adyacentes (gi,gj ±1). Suma de su actividad reciente.
    zinfo = panel[["zone_id", "gi", "gj"]].drop_duplicates().set_index("zone_id")
    gi_gj_to_zone = {(r.gi, r.gj): z for z, r in zinfo.iterrows()}
    neighbors: dict[str, list[str]] = {}
    for z, r in zinfo.iterrows():
        nb = []
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                if di == 0 and dj == 0:
                    continue
                key = (r.gi + di, r.gj + dj)
                if key in gi_gj_to_zone:
                    nb.append(gi_gj_to_zone[key])
        neighbors[z] = nb
    pivot24 = panel.pivot_table(index="ts", columns="zone_id", values="inc_last_24h", fill_value=0)
    adj_series = {
        z: (pivot24[neighbors[z]].sum(axis=1) if neighbors[z] else pd.Series(0.0, index=pivot24.index))
        for z in neighbors
    }
    panel["inc_adj_24h"] = panel.apply(lambda r: float(adj_series[r["zone_id"]].get(r["ts"], 0.0)), axis=1)

    panel[LAG_COLS] = panel[LAG_COLS].fillna(0)

    zone_cat = panel["zone_id"].astype("category")
    panel["zone_code"] = zone_cat.cat.codes
    zone_to_code = {z: i for i, z in enumerate(zone_cat.cat.categories)}
    return panel, zone_to_code


def main() -> None:
    print("Generando incidentes sintéticos...")
    raw = build_raw()
    panel = build_panel(raw)
    panel, zone_to_code = add_features(panel)
    print(f"Panel: {panel.shape} | zonas: {panel['zone_id'].nunique()} | "
          f"% bins con incidentes: {(panel['count'] > 0).mean() * 100:.2f}%")

    # Split TEMPORAL (no aleatorio: mezclar fechas contaminaría los lags).
    dates = pd.date_range(START, periods=N_DAYS, freq="D")
    cutoff = dates[int(N_DAYS * 0.8)]
    train = panel[panel["date"] < cutoff]
    test = panel[panel["date"] >= cutoff]

    model = xgb.XGBRegressor(
        objective="count:poisson",  # target = CONTEO → Poisson, no regresión común
        n_estimators=400, max_depth=6, learning_rate=0.05,
        subsample=0.9, colsample_bytree=0.9, min_child_weight=5,
        random_state=7, n_jobs=-1,
    )
    model.fit(train[FEATURES], train[TARGET], eval_set=[(test[FEATURES], test[TARGET])], verbose=False)

    pred = np.clip(model.predict(test[FEATURES]), 0, None)
    print(f"MAE: {mean_absolute_error(test[TARGET], pred):.4f} | "
          f"RMSE: {mean_squared_error(test[TARGET], pred) ** 0.5:.4f} | "
          f"Poisson deviance: {mean_poisson_deviance(test[TARGET], np.clip(pred, 1e-6, None)):.4f}")
    imp = pd.Series(model.feature_importances_, index=FEATURES).sort_values(ascending=False)
    print("Top features:", ", ".join(f"{k}={v:.3f}" for k, v in imp.head(5).items()))

    # λ (conteo esperado) → risk_score 0-100. Tope = p99 del train (decisión de producto).
    lambda_cap = float(max(0.5, np.quantile(model.predict(train[FEATURES]), 0.99)))

    # Tabla de lags de SERVING por (zone_id, hora): media de cada lag sobre el
    # histórico. Es el "nivel típico de actividad reciente" de esa zona a esa
    # hora — permite predecir sin consultar la BD en cada request. En producción
    # se reemplaza por lags reales (incidentes recientes por zona vía BD/Redis).
    serving = (
        panel.groupby(["zone_id", "hour"])[LAG_COLS].mean().round(4)
        .reset_index()
    )
    serving_lags: dict[str, dict[int, dict[str, float]]] = {}
    for _, r in serving.iterrows():
        serving_lags.setdefault(r["zone_id"], {})[int(r["hour"])] = {c: float(r[c]) for c in LAG_COLS}

    zc = panel[["zone_id", "zone_lat", "zone_lng"]].drop_duplicates().set_index("zone_id")
    bundle = {
        "version": "v1-xgb-poisson",
        "model": model,
        "features": FEATURES,
        "lag_cols": LAG_COLS,
        "lambda_cap": lambda_cap,
        "tile": TILE, "lat_min": LAT_MIN, "lng_min": LNG_MIN,
        "zone_to_code": zone_to_code,
        "zone_centers": {z: (float(r.zone_lat), float(r.zone_lng)) for z, r in zc.iterrows()},
        "serving_lags": serving_lags,
    }

    out = Path(__file__).resolve().parent.parent / "src" / "models" / "predictor_v1.joblib"
    out.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(bundle, out)
    print(f"Guardado: {out} | zonas: {len(zone_to_code)} | lambda_cap: {lambda_cap:.3f}")


if __name__ == "__main__":
    main()
