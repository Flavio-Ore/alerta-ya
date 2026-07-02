"""Monitoreo de drift de datos para el verificador ML.

Drift = el input de producción se aleja de la distribución con la que se entrenó
el modelo. Cuando eso pasa, las predicciones dejan de ser confiables y toca
re-entrenar. Medimos drift con PSI (Population Stability Index), el estándar de
la industria para comparar dos distribuciones.

Interpretación PSI (convención):
  < 0.10  → sin cambio relevante
  0.10–0.25 → cambio moderado, vigilar
  >= 0.25 → cambio significativo, re-entrenar

Lógica pura (numpy/pandas) — sin dependencias del bundle del modelo, así corre
independiente de la versión del verifier.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

#: Umbral de PSI a partir del cual se marca drift significativo.
DRIFT_THRESHOLD = 0.25

_EPS = 1e-6


def population_stability_index(
    expected: np.ndarray, actual: np.ndarray, bins: int = 10
) -> float:
    """PSI entre una distribución `expected` (baseline de entrenamiento) y `actual`.

    Los cortes se derivan de los cuantiles de `expected`, de modo que cada bin del
    baseline tiene ~la misma masa. PSI es simétrico-ish y >= 0; 0 = distribuciones
    idénticas.
    """
    expected = np.asarray(expected, dtype=float)
    actual = np.asarray(actual, dtype=float)

    if expected.size == 0 or actual.size == 0:
        return 0.0

    # Cortes por cuantiles del baseline; bordes infinitos para cubrir cualquier valor.
    quantiles = np.linspace(0, 1, bins + 1)
    edges = np.quantile(expected, quantiles)
    edges = np.unique(edges)  # colapsa cortes repetidos (features casi constantes)
    if edges.size < 2:
        # Feature constante en el baseline: no hay distribución que comparar.
        return 0.0
    edges[0] = -np.inf
    edges[-1] = np.inf

    e_counts = np.histogram(expected, bins=edges)[0].astype(float)
    a_counts = np.histogram(actual, bins=edges)[0].astype(float)

    e_perc = np.clip(e_counts / expected.size, _EPS, None)
    a_perc = np.clip(a_counts / actual.size, _EPS, None)

    return float(np.sum((a_perc - e_perc) * np.log(a_perc / e_perc)))


def compute_drift(
    baseline: pd.DataFrame,
    current: pd.DataFrame,
    features: list[str],
    threshold: float = DRIFT_THRESHOLD,
) -> dict:
    """Reporte de drift por feature entre `baseline` y `current`.

    Retorna un dict serializable a JSON:
      {
        "features": {feat: {"psi": float, "drifted": bool}},
        "drift_detected": bool,   # True si alguna feature superó el umbral
        "threshold": float,
      }
    """
    report: dict[str, dict] = {}
    for feat in features:
        psi = population_stability_index(baseline[feat].to_numpy(), current[feat].to_numpy())
        report[feat] = {"psi": round(psi, 4), "drifted": psi >= threshold}

    return {
        "features": report,
        "drift_detected": any(v["drifted"] for v in report.values()),
        "threshold": threshold,
    }
