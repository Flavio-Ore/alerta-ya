# Retraining & Monitoring — AlertaYa (Fase I)

Cómo se mantiene fresco el modelo ML y el artefacto de riesgo. Cubre lo que ya
está automatizado (código en el repo) y lo que se activa en el despliegue
(Cloud Scheduler + datos reales).

---

## 1. Recompute del riesgo (automatizado)

El artefacto `api/data/risk-hourly.json` que sirve `GET /risk` es un precompute
estático. Sin recompute, envejece.

**Job:** `POST /internal/jobs/recompute-risk`
- Protegido con header `X-Job-Secret: {JOB_SECRET}`.
- Recalcula el artefacto (DATACRIM espacial + seed temporal) y refresca el cache
  en memoria del endpoint. Fail-safe: nunca tumba el proceso.
- Código: `api/src/core/jobs/recompute-risk.job.ts` → `recomputeRiskArtifact()`.

**Cloud Scheduler (GCP) — diario 04:00:**
```
gcloud scheduler jobs create http recompute-risk \
  --schedule="0 4 * * *" \
  --uri="https://<api-host>/internal/jobs/recompute-risk" \
  --http-method=POST \
  --headers="X-Job-Secret=<JOB_SECRET>"
```

**Pendiente de deploy (riesgo dinámico real):** hoy la señal temporal viene solo
del `seed`. En producción, alimentar `recomputeRiskArtifact()` también con los
incidentes recientes de la base (últimos N días) como señal temporal viva. El
cálculo (`computeRiskArtifact(tiles, seed)`) ya acepta cualquier lista de
incidentes; falta el query a la DB (no disponible en el entorno local).

---

## 2. Monitoreo de drift (automatizado)

Drift = el input de producción se aleja de la distribución de entrenamiento →
las predicciones dejan de ser confiables. Se mide con PSI (Population Stability
Index).

**Script:** `ml/scripts/drift_monitor.py`
```
uv run python scripts/drift_monitor.py \
  --baseline data/train_features.csv \
  --current  data/recent_features.csv \
  --features photo_age hour_sin hour_cos
```
- Imprime un reporte JSON por feature (`psi`, `drifted`).
- Exit code `1` si alguna feature superó el umbral (default PSI ≥ 0.25) — útil
  para que un cron dispare una alerta o el re-entrenamiento.
- Lógica pura y testeada: `ml/src/features/monitoring/drift.py`.

Umbrales (convención): `< 0.10` estable · `0.10–0.25` vigilar · `≥ 0.25` re-entrenar.

**Cloud Scheduler — semanal:** exportar features recientes desde la DB a CSV,
correr el script; si sale `1`, notificar / encolar retrain.

---

## 3. Re-entrenamiento del verificador (semi-automatizado)

**Estado actual:** el verifier vive en el stack `evidence-authenticity` (Fase D):
`verifier_v3.joblib` + `ml/scripts/train_verifier_v3.py`. Entrenado con datos
**sintéticos** — placeholder hasta tener reportes reales etiquetados.

**Flujo de retrain (cuando haya datos reales):**
1. Etiquetar reportes reales (verificado / sospechoso) → dataset de entrenamiento.
2. Correr `uv run python scripts/train_verifier_v3.py` → nuevo `verifier_vN.joblib`.
3. Apuntar la config del predictor al nuevo bundle y versionar el `.joblib`.
4. Validar contra el set de holdout antes de promover a producción.

> **Dependencia de integración:** el retrain requiere que el stack Fase D
> (`feat/evidence-auth-*`) esté mergeado. La rama actual (`feat/reputation-tier-s1`,
> stack F→G→H) trae el recompute de riesgo y el monitor de drift, pero **no** el
> `train_verifier_v3.py`. Coordinar el merge de los stacks antes de cablear el
> retrain periódico end-to-end.

**Periodicidad sugerida:** mensual, o disparado por drift (§2), lo que ocurra primero.
