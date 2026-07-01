# AI_VALIDATION.md — Validación de reportes con IA

> Fuente de verdad sobre cómo AlertaYa evalúa la autenticidad de un reporte con IA,
> qué significa cada porcentaje/métrica, y qué datos (DATACRIM) se usaron.
> Referencias `archivo:línea` verificadas contra el código al 2026-07-01.

---

## 1. Resumen del pipeline

Cuando un usuario crea un **reporte nuevo** que cruza el umbral de publicación
(`evaluateThreshold` → `decision.publish === true`) y genera un **incidente nuevo**,
se dispara la validación IA. El flujo corre en `create-report.usecase.ts`.

```
Reporte nuevo (publica + incidente nuevo)
        │
        ├── Fase A · ML verifier (anomalía metadata)      → mlScore ∈ [0,1], verified bool
        ├── Fase C · Visión GLM-4V (foto vs tipo)         → visionMatch ∈ {-1, 0, +1, null}
        │        (A y C corren EN PARALELO — Promise.allSettled)
        ▼
   finalScore = clamp(mlScore * (1 + k · visionMatch), 0, 1)
        ▼
   aiVerified = finalScore >= 0.5
        ▼
   Δ reputación (según verified + evidencia) → push al usuario
```

Todo el pipeline es **fail-open**: si el ML o la visión fallan (timeout, sin key, error red),
no bloquean el reporte — el reporte se publica igual, con la métrica en `null`.

Solo se ejecuta en la **primera creación de incidente**. Reportes que actualizan un
incidente existente NO vuelven a llamar al ML.

---

## 2. Fase A — ML Verifier (detección de anomalía)

**Servicio:** `ml/` (Python) · **Modelo:** `ml/src/models/verifier_v2.joblib`
**Predictor:** `ml/src/features/verification/infrastructure/verifier_predictor.py`

### Algoritmo
Ensamble de dos detectores de anomalía con lógica **AND**:

| Detector | Librería | Config |
|----------|----------|--------|
| **ECOD** | PyOD | detección por distribución empírica |
| **IsolationForest** | scikit-learn | 200 estimadores, `contamination = 0.05` |

- `is_anomaly = ecod_anomaly AND iforest_anomaly` (ambos deben coincidir para marcar incoherente).
- Entrenado solo con datos **coherentes** (novelty detection): el modelo aprende cómo se ve un reporte "normal" y marca los que se desvían.

### Features (16) — `_build_features()` (`verifier_predictor.py:39-78`)

| # | Feature | Derivación |
|---|---------|-----------|
| 1-2 | `lat`, `lng` | coordenadas crudas |
| 3-4 | `hour_sin`, `hour_cos` | `sin/cos(2π·hora/24)` — hora cíclica |
| 5-6 | `dow_sin`, `dow_cos` | `sin/cos(2π·día_semana/7)` — día cíclico |
| 7 | `weapon_lvl` | `{none:0, knife:1, firearm:2}` |
| 8 | `injured_lvl` | `{no:0, yes:1}` |
| 9 | `report_count` | nº de reportes del incidente |
| 10-14 | `type_ROBBERY`, `type_ACCIDENT`, `type_HARASSMENT`, `type_EXTORTION`, `type_SUSPICIOUS` | one-hot del tipo (`handle_unknown='ignore'`) |
| 15 | `has_evidence` | `1.0` si hay media, `0.0` si no |
| 16 | `photo_age_minutes` | edad de la foto, recortada a `[0, 999]` (999 = ausente) |

Features 15-16 son las adiciones de la **Fase B (evidencia)**; se agregaron al final para no romper el orden del bundle v1.

### Cómo se convierte en porcentaje (`verifier_predictor.py:109-111`)

- `p_out` = probabilidad de outlier según ECOD (0.0–1.0).
- **Si es anomalía:** `confidence = p_out`
- **Si es normal:** `confidence = 1.0 - p_out`
- Redondeado a 3 decimales.

`score` = confianza en la **coherencia** del reporte. Cerca de `1.0` = muy coherente; cerca de `0.0` = incoherente/sospechoso.

### Contrato del endpoint `POST /ml/verify` (`router.py:28-41`)

**Request:** `report_id, lat, lng, type, form_data, user_reputation (0.5 def), has_evidence (false def), photo_age_minutes (opt)`
**Response:** `{ score: float 0..1, verified: bool }`

Cliente API: `ml.client.ts` — timeout **800 ms** (`ML_TIMEOUT_MS`).

---

## 3. Fase C — Visión GLM-4V (foto vs tipo declarado)

**Cliente:** `glm.client.ts:206-251` · **Modelo:** `glm-4v-flash` (`env.ts:43`)

`analyzeImage(imageUrl, incidentType)` mira la primera foto y devuelve:

| Valor | Significado |
|-------|-------------|
| `+1.0` | CONSISTENT — la foto muestra plausiblemente el tipo de incidente |
| `-1.0` | INCONSISTENT — la foto contradice el tipo declarado |
| `0.0` | INDETERMINATE — borrosa, oscura, ambigua |
| `null` | fail-open (sin key, error red, timeout, no-2xx) |

Timeout: **3000 ms** (`GLM_VISION_TIMEOUT_MS`). Corre en paralelo con la Fase A.

---

## 4. Combinación — finalScore y aiVerified

`create-report.usecase.ts:188-197`

```
k = VISION_SCORE_K            // default 0.2  (env.ts:52)
finalScore = clamp( mlScore * (1 + k · visionMatch), 0, 1 )
aiVerified = finalScore >= AI_VERIFIED_THRESHOLD   // 0.5  (ml.client.ts:4)
```

Efecto del multiplicador de visión (con k=0.2):

| visionMatch | factor | efecto sobre mlScore |
|-------------|--------|----------------------|
| `+1.0` (consistente) | 1.2 | +20% |
| `0.0` (indeterminado) | 1.0 | sin cambio |
| `-1.0` (inconsistente) | 0.8 | −20% |
| `null` (sin visión) | 1.0 | sin cambio |

- `finalScore === null` solo si el ML mismo falló (visión null NO anula el score).
- `aiVerified`: `true` si ≥ 0.5, `false` si < 0.5, `null` si sin score.

Se persiste en `Incident.aiScore` (Float?) y `Incident.aiVerified` (Boolean?), y en `Report.aiScore/aiVerified`.

---

## 5. Reputación — impacto en el usuario

`reputation.ts:7-26` · `computeReputationDelta(verified, hasEvidence)`

| verified | evidencia | Δ puntos |
|----------|-----------|----------|
| ✓ true | con foto | **+5** |
| ✓ true | sin foto | **+3** |
| ✗ false | con foto | **−1** |
| ✗ false | sin foto | **−2** |

- Se aplica solo si `finalScore !== null`. Patrón fire-and-forget (no bloquea la respuesta).
- `User.reputationScore` arranca en 100.
- Se envía push al usuario: "Reporte verificado ✓ (+N)" o "Reporte marcado como sospechoso (−N)".

---

## 6. Qué significa cada número — para panel web y para el usuario

El panel web hoy solo muestra el `%` de IA sin contexto. Estas son TODAS las señales
disponibles para dar detalle. Recomendación de desglose:

| Campo | Rango | Lectura para autoridad | Lectura para el ciudadano |
|-------|-------|------------------------|---------------------------|
| `aiScore` (finalScore) | 0.0–1.0 → mostrar como % | Confianza de coherencia del reporte | "Qué tan consistente se ve tu reporte" |
| `aiVerified` | true/false/null | Verde ✓ / Ámbar ⚠ / "sin evaluar" | "Verificado" / "Requiere revisión" |
| `visionMatch` | +1 / 0 / −1 / null | La foto ¿coincide con el tipo? | "Tu foto respalda el reporte" |
| `has_evidence` | bool | ¿Adjuntó foto? | — |
| `photo_age_minutes` | 0–999 | Frescura de la foto (999 = sin foto) | "Foto tomada hace X min" |
| `Δ reputación` | +5/+3/−1/−2 | Impacto en confiabilidad del usuario | "Ganaste/perdiste N puntos" |

**Para el usuario:** con esto puede saber *por qué* su reporte quedó bien o mal —
no solo un número, sino: evidencia sí/no, foto fresca o vieja, foto coincide o no, y el delta de reputación.

---

## 7. DATACRIM — datos usados para el análisis

**Qué es:** base histórica de delitos del INEI (Perú), puntos georreferenciados 2017–2020.
**Fuente:** ArcGIS REST MapServer del INEI
`http://arcgis3.inei.gob.pe:6080/arcgis/rest/services/Datacrim/DATACRIM002_AGS_PUNTOSDELITOS/MapServer`
**Extractor:** `extract_datacrim.py`

### Extracción
- Bounding box Lima: `xmin=-77.20, xmax=-76.75, ymin=-12.30, ymax=-11.70`. **Ojo: en DATACRIM X=lng, Y=lat.**
- 290+ capas (una por tipo de delito × periodo), sin esquema uniforme (campos varían: `periodo`/`AÑO`, `generico`/`GENERICO`).
- Batch de 500 vía `OBJECTID IN` (el MapServer no soporta paginación por offset), `outFields=*`.

### Campos normalizados en el CSV de salida (`extract_datacrim.py:62-70`)
`incident_generic`, `incident_specific`, `district`, `ubigeo`, `lat`, `lng`, `year`, `source_layer`.

### Limitación clave
El campo temporal es **AÑO** (solo año, no fecha/día/hora). Por eso DATACRIM sirve para
**modelado espacial** (zonas de riesgo por distrito), NO para patrones horarios ni de día de semana.

### Uso en la app
Contexto histórico para el asistente GLM (`glm.client.ts:52-92`): top 15 distritos por riesgo
y conteos por tipo de delito, como grounding de las respuestas de IA.

---

## 8. Caveats conocidos (deuda técnica)

1. **Mismatch de tipos de incidente entre modelo y producción.**
   El bundle `verifier_v2.joblib` fue entrenado con `incident_types = [ROBBERY, ASSAULT, THEFT, VANDALISM, SUSPICIOUS]`
   (`train_verifier_v2.py`), pero el enum real de Prisma es `[ROBBERY, ACCIDENT, HARASSMENT, EXTORTION, SUSPICIOUS]`.
   Como el OHE usa `handle_unknown='ignore'`, los one-hots de ACCIDENT/HARASSMENT/EXTORTION salen en **cero**
   (tratados como desconocidos) y las columnas ASSAULT/THEFT/VANDALISM quedan muertas. El modelo pierde
   la señal de tipo para 3 de 5 categorías reales. **Acción sugerida: re-entrenar con el enum de producción.**

2. **DATACRIM sin granularidad horaria** → las features `hour_*` y `dow_*` no se calibraron con datos reales
   de hora; provienen del reporte en vivo, no de histórico. Las "estadísticas por hora/fecha" del roadmap
   necesitan otra fuente o datos propios acumulados.

3. **k (VISION_SCORE_K=0.2) es heurístico**, no aprendido. Ajustar empíricamente cuando haya datos etiquetados.

---

## 9. Referencias de archivos

| Concepto | Archivo |
|----------|---------|
| Features + score ML | `ml/src/features/verification/infrastructure/verifier_predictor.py` |
| Entrenamiento v2 | `ml/.../train_verifier_v2.py` |
| Endpoint verify | `ml/src/features/verification/presentation/router.py` |
| Cliente ML + umbral | `api/src/features/incidents/infrastructure/ml.client.ts` |
| Visión GLM-4V | `api/src/features/incidents/infrastructure/glm.client.ts` |
| Orquestación scoring | `api/src/features/incidents/domain/usecases/create-report.usecase.ts` |
| Reputación | `api/src/.../reputation.ts` |
| Extractor DATACRIM | `ml/.../extract_datacrim.py` |
| Modelos de datos | `api/prisma/schema.prisma` |
