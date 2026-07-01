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

**Servicio:** `ml/` (Python) · **Modelo:** `ml/src/models/verifier_v3.joblib`
(default desde `config.py:22`; `verifier_v2.joblib` se mantiene en disco, sin usarse, como rollback — ver Caveats §9.1)
**Predictor:** `ml/src/features/verification/infrastructure/verifier_predictor.py`

### Algoritmo
Ensamble de dos detectores de anomalía con lógica **AND**:

| Detector | Librería | Config |
|----------|----------|--------|
| **ECOD** | PyOD | detección por distribución empírica |
| **IsolationForest** | scikit-learn | 200 estimadores, `contamination = 0.05` |

- `is_anomaly = ecod_anomaly AND iforest_anomaly` (ambos deben coincidir para marcar incoherente).
- Entrenado solo con datos **coherentes** (novelty detection): el modelo aprende cómo se ve un reporte "normal" y marca los que se desvían.

### Features (17) — `_build_features()` (`verifier_predictor.py:39-86`)

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
| 17 | `photo_trusted` | `1.0` si `photo_source === 'exif'`, `0.0` en cualquier otro caso (`device_clock`, ausente) — ver §7.6 |

Features 15-16 son las adiciones de la **Fase B (evidencia)**; la 17 (`photo_trusted`) es la adición de **v3** (evidence-authenticity S4). Todas se agregaron al final del vector, respetando el orden original del bundle v1 — ver §7 para el detalle de por qué esto mantiene compatibilidad hacia atrás.

### Cómo se convierte en porcentaje (`verifier_predictor.py:118-119`)

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

## 7. Matemática del verifier ML — ECOD + IsolationForest (detalle técnico)

> **Alcance de esta sección:** únicamente el ensemble estadístico del verifier (`verifier_predictor.py` /
> `train_verifier_v3.py`). **No cubre** las estadísticas espaciales de DATACRIM (§8) — esa derivación
> (`03_spatial_risk.ipynb`) no fue leída ni verificada al escribir esta sección y queda fuera de alcance.

### 7.1 ECOD — Empirical Cumulative Distribution-based Outlier Detection

ECOD (PyOD) estima, para cada feature del vector de entrada, la función de distribución empírica (CDF)
de esa dimensión sobre los datos de entrenamiento, y calcula qué tan lejos cae un valor nuevo en las
**colas** de esa distribución (probabilidad de cola izquierda y derecha). Combina esas probabilidades de
cola por dimensión en un score de anomalía agregado.

Intuición: un reporte cuyo `hour_sin`/`hour_cos` cae en una franja horaria muy poco frecuente, o cuyo
`report_count` es extremadamente alto comparado con la mayoría de incidentes, tiene una probabilidad de
cola baja en esa dimensión → contribuye a un score de anomalía más alto.

Por qué es "parameter-light": ECOD **no asume una distribución paramétrica** (no asume gaussiana, no
asume un kernel específico) — estima la CDF empíricamente a partir de los propios datos de entrenamiento.
Esto lo hace más simple de calibrar que métodos que requieren ajustar densidad (ej. KDE) y razonablemente
robusto ante features con distribuciones heterogéneas (coordenadas, ángulos cíclicos, conteos, niveles
ordinales) sin necesitar una transformación previa por feature.

### 7.2 IsolationForest — partición aleatoria y longitud de camino

IsolationForest (`train_verifier_v3.py:245`, `n_estimators=200`) construye un bosque de árboles donde
cada nodo divide el espacio de features con un corte **aleatorio** (feature aleatoria + umbral aleatorio).
Un punto anómalo, al estar aislado del resto, tiende a quedar separado del resto de los datos en **pocos
cortes** — es decir, tiene una longitud de camino (path length) corta hasta volverse una hoja. Un punto
normal, rodeado de vecinos similares, necesita muchos más cortes para aislarse.

El score de anomalía de sklearn se deriva de esa longitud de camino promediada sobre los 200 árboles:
caminos más cortos → score más anómalo. `contamination=0.05` (`train_verifier_v3.py:240`) le dice al
modelo que espere ~5% de los datos de entrenamiento como outliers, y fija el umbral de decisión (`predict()`
devuelve `-1` = outlier) en ese percentil. `n_estimators=200` es el tamaño del bosque — más árboles
estabilizan el promedio de longitud de camino sin cambiar la lógica del algoritmo.

### 7.3 Ensemble — regla AND

`is_anomaly = ecod_anomaly AND iforest_anomaly` (`verifier_predictor.py:114-116`,
`train_verifier_v3.py:258-260`): un reporte solo se marca incoherente si **ambos** detectores coinciden.

Por qué AND y no OR ni un promedio: los dos algoritmos capturan nociones distintas de "anómalo" (colas de
distribución vs. aislamiento estructural), así que su intersección es más conservadora que cualquiera de
los dos por separado. Esto es una decisión deliberada de **precisión sobre recall**: en un contexto de
seguridad ciudadana, marcar un reporte legítimo como "incoherente" (falso positivo) tiene un costo social
mayor que dejar pasar un reporte anómalo sin marcar (falso negativo) — el pipeline es fail-open e
informativo en todo el resto del flujo, así que esta es la única capa donde se prioriza explícitamente no
sobre-marcar.

### 7.4 De p_out a confidence

`p_out` es la probabilidad de outlier según ECOD (`ecod.predict_proba(x)[0, 1]`,
`verifier_predictor.py:118`) — un score normalizado en `[0, 1]`, no una probabilidad bayesiana calibrada.

```
confidence = p_out        si is_anomaly
confidence = 1.0 - p_out  si no
```

(`verifier_predictor.py:119`), redondeado a 3 decimales. El resultado siempre cae en `[0, 1]`:
`confidence` cercano a `1.0` = alta confianza en la lectura del ensemble (ya sea "coherente" o
"incoherente" según corresponda); cercano a `0.5` = zona ambigua, cerca del umbral de decisión de ECOD.

### 7.5 Codificación cíclica — por qué sin/cos para hora y día de semana

`hour_sin/hour_cos = sin/cos(2π·hora/24)`, `dow_sin/dow_cos = sin/cos(2π·día_semana/7)`
(`verifier_predictor.py:60-63`, `train_verifier_v3.py:182-185`).

Una hora o un día de semana codificados como entero crudo (`hour=23` vs `hour=0`) le dicen al modelo que
la distancia entre las 23:00 y la medianoche es `|23-0| = 23`, cuando en realidad son **adyacentes** (1
hora de diferencia). Ese error de distancia rompe cualquier detector basado en cercanía o densidad local
(ECOD e IsolationForest ambos son sensibles a esto). Proyectar la hora sobre el círculo unitario
(`sin`, `cos`) hace que las 23:00 y las 00:00 queden geométricamente cerca en el plano `(sin, cos)`,
preservando la continuidad real del ciclo. Se necesitan **ambas** componentes (seno y coseno) porque una
sola no es inyectiva sobre el círculo (dos horas distintas pueden compartir el mismo seno) — el par
`(sin, cos)` sí identifica un punto único del ciclo. Mismo razonamiento aplica a `day_of_week` sobre un
ciclo de 7.

### 7.6 El sentinel 999 — `photo_age_minutes`

`photo_age_minutes` se recorta a `[0, 999]`; si la foto está ausente o su origen no es confiable, el valor
es `999.0` (`verifier_predictor.py:77`) — el peor caso dentro del rango, nunca `null`/`NaN` (los
detectores no toleran valores faltantes).

Este sentinel está directamente enlazado con la corrección de confianza de EXIF introducida en **S3**
(evidence-authenticity): `create-report.usecase.ts` solo calcula una edad real cuando `photoSource ===
'exif'`; si el origen es `device_clock` (reloj del dispositivo, falsificable) o está ausente, la edad se
pasa como `null` al ML, y el predictor la traduce a `999` — es decir, una foto de origen no confiable se
trata como si fuera "ausente o muy vieja", nunca como "fresca". `photo_trusted` (§7 features, ver tabla en
§2) es la contraparte v3 de esta misma señal: una feature booleana explícita (`1.0` si `exif`, `0.0` si
no) que el ensemble puede usar directamente, en vez de inferir la confianza indirectamente a través del
valor de edad.

### 7.7 Combinación post-ML — recordatorio y diseño aditivo de v3

La combinación de `mlScore` (esta sección) con `visionMatch` (Fase C) ya está descrita en §4:

```
finalScore  = clamp( mlScore * (1 + k · visionMatch), 0, 1 )     // k = VISION_SCORE_K = 0.2
aiVerified  = finalScore >= 0.5
```

Ese cálculo vive enteramente en `api/` (`create-report.usecase.ts`) y es **independiente** de qué versión
del bundle (`v2`/`v3`) esté cargada en `ml/` — el contrato del ML solo cambia el `mlScore` de entrada, no
la fórmula de combinación.

Diseño aditivo de v3: `photo_trusted` se agregó **al final** de `feature_columns`, exactamente con el
mismo criterio que `has_evidence`/`photo_age_minutes` en v2 (`verifier_predictor.py:79-84`,
`train_verifier_v3.py:216-221`). La selección final de columnas (`pd.DataFrame([row])[b["feature_columns"]]`)
lee el orden desde el propio bundle, así que un bundle `v2` cargado con el código actual simplemente
**no tiene** `photo_trusted` en su lista y la descarta automáticamente — no hace falta ninguna
rama condicional en el predictor para soportar ambas versiones a la vez. Esto es lo que permite el
rollback de `v3` a `v2` con un cambio de un solo path en `config.py`, sin tocar código.

### 7.8 Limitación conocida de v3 — datos sintéticos

El dataset de entrenamiento de `train_verifier_v3.py` (2100 filas: 2000 normales + 100 anómalas) es
**enteramente sintético** — generado con distribuciones y correlaciones (`TYPE_PROFILES`, `CLASS_PROBS`,
`_photo_provenance`) definidas a mano como valores por defecto razonables, no ajustadas contra reportes
reales de la base de AlertaYa. El fix del enum (§9.1) es real y verificable (los 5 tipos de incidente
ahora producen un one-hot no-nulo), pero las probabilidades condicionales de arma/lesión por tipo de
incidente, y el propio criterio de qué hace "anómalo" a un reporte, siguen siendo un juicio de diseño, no
un resultado aprendido de datos históricos. Un re-entrenamiento futuro contra datos reales de `Report`
produciría un modelo materialmente mejor calibrado.

---

## 8. DATACRIM — datos usados para el análisis

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

## 9. Caveats conocidos (deuda técnica)

1. **Mismatch de tipos de incidente entre modelo y producción — RESUELTO en v3.**
   `verifier_v2.joblib` fue entrenado con `incident_types = [ROBBERY, ASSAULT, THEFT, VANDALISM, SUSPICIOUS]`
   (`train_verifier_v2.py`), que nunca coincidió con el enum real de Prisma
   `[ROBBERY, ACCIDENT, HARASSMENT, EXTORTION, SUSPICIOUS]`. Con `handle_unknown='ignore'`, los one-hots de
   ACCIDENT/HARASSMENT/EXTORTION salían en **cero** en producción (tratados como desconocidos) y las
   columnas ASSAULT/THEFT/VANDALISM quedaban muertas — el modelo v2 nunca vio una señal de tipo real para
   3 de 5 categorías de producción.
   `verifier_v3.joblib` (`train_verifier_v3.py:54`, activo por defecto desde `config.py:22`) corrige el
   enum a los 5 tipos reales de Prisma y agrega la feature `photo_trusted` (§7.6-7.7). La limitación
   restante de v3 es el dataset **sintético** (§7.8), no el enum. `verifier_v2.joblib` se conserva en disco
   sin usarse, solo como ruta de rollback (cambio de un solo path en `config.py`, sin redeploy de modelo).

2. **DATACRIM sin granularidad horaria** → las features `hour_*` y `dow_*` no se calibraron con datos reales
   de hora; provienen del reporte en vivo, no de histórico. Las "estadísticas por hora/fecha" del roadmap
   necesitan otra fuente o datos propios acumulados.

3. **k (VISION_SCORE_K=0.2) es heurístico**, no aprendido. Ajustar empíricamente cuando haya datos etiquetados.

4. **`photo_source` es asertado por el cliente** (ver §7.6): un cliente malicioso podría enviar
   `photo_source: 'exif'` con un `photoTakenAt` arbitrario — `photo_trusted` es puramente informativo
   (una feature más del ensemble, nunca un gate por sí sola) precisamente porque este límite de confianza
   no se puede cerrar del todo en la capa ML. Cerrarlo requeriría re-verificar el EXIF en el servidor, en
   la capa `api/` (fuera de alcance de evidence-authenticity Fase D).

---

## 10. Referencias de archivos

| Concepto | Archivo |
|----------|---------|
| Features + score ML | `ml/src/features/verification/infrastructure/verifier_predictor.py` |
| Entrenamiento v2 (histórico) | `ml/.../train_verifier_v2.py` |
| Entrenamiento v3 (activo) | `ml/notebooks/train_verifier_v3.py` |
| Endpoint verify | `ml/src/features/verification/presentation/router.py` |
| Config (path del modelo activo) | `ml/src/core/config.py` |
| Cliente ML + umbral | `api/src/features/incidents/infrastructure/ml.client.ts` |
| Visión GLM-4V | `api/src/features/incidents/infrastructure/glm.client.ts` |
| Orquestación scoring | `api/src/features/incidents/domain/usecases/create-report.usecase.ts` |
| Reputación | `api/src/.../reputation.ts` |
| Extractor DATACRIM | `ml/.../extract_datacrim.py` |
| Modelos de datos | `api/prisma/schema.prisma` |
