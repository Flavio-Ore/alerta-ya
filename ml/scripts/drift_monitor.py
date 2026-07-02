"""CLI de monitoreo de drift — compara un baseline de features contra un batch actual.

Uso:
  uv run python scripts/drift_monitor.py --baseline data/train_features.csv \\
      --current data/recent_features.csv --features photo_age hour_sin hour_cos

Ambos CSV deben tener las columnas listadas en --features. Imprime un reporte
JSON por stdout y sale con codigo 1 si se detecta drift (util para Cloud
Scheduler / CI: un exit != 0 puede disparar una alerta o un re-entrenamiento).

Este script NO re-entrena por si mismo: solo mide. El re-entrenamiento periodico
se dispara a partir de esta senal (ver docs/architecture/RETRAINING.md).
"""

from __future__ import annotations

import argparse
import json
import sys

import pandas as pd

# Permite ejecutar el script directamente (`python scripts/drift_monitor.py`)
# resolviendo el paquete `src` sin instalar.
sys.path.insert(0, __file__.rsplit("/scripts/", 1)[0])

from src.features.monitoring.drift import DRIFT_THRESHOLD, compute_drift  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Monitor de drift (PSI).")
    parser.add_argument("--baseline", required=True, help="CSV con la distribucion de entrenamiento")
    parser.add_argument("--current", required=True, help="CSV con el batch reciente de produccion")
    parser.add_argument("--features", required=True, nargs="+", help="Columnas a evaluar")
    parser.add_argument(
        "--threshold", type=float, default=DRIFT_THRESHOLD, help="Umbral de PSI (default 0.25)"
    )
    args = parser.parse_args()

    baseline = pd.read_csv(args.baseline)
    current = pd.read_csv(args.current)

    report = compute_drift(baseline, current, args.features, threshold=args.threshold)
    print(json.dumps(report, indent=2))

    return 1 if report["drift_detected"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
