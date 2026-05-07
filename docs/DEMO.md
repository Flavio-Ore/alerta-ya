# DEMO.md — Guía de Presentación AlertaYa

> Ubicación demo: **Av. El Sol 235, San Juan de Lurigancho 15096**
> Coordenadas: `lat: -11.9800, lng: -77.0050`

---

## Estado requerido por servicio

| Servicio | Necesario para demo | Mínimo aceptable |
|----------|--------------------|--------------------|
| `api/` | ✅ Sí | Corriendo en `localhost:3000` |
| `web/` | ✅ Sí | Panel web mostrando mapa con incidentes |
| `mobile/` | ✅ Sí | Al menos 1 dispositivo real para reportar |
| `ml/` | ⚠️ Opcional | Solo si querés mostrar IA verification |
| PostgreSQL | ✅ Sí | Docker o Cloud SQL |
| Redis | ✅ Sí | Docker o Redis Cloud |

---

## 1. Preparación — hacer ANTES del día de demo

### 1.1 Variables de entorno

```bash
# Backend
cp api/.env.example api/.env
```

Completar en `api/.env`:
```env
DATABASE_URL=postgresql://alertaya:alertaya@localhost:5432/alertaya_dev
REDIS_URL=redis://localhost:6379
FIREBASE_PROJECT_ID=tu-proyecto
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
GCS_BUCKET_NAME=alertaya-panic-recordings
GCP_PROJECT_ID=tu-proyecto-gcp
WEB_URL=http://localhost:5173
ML_SERVICE_URL=http://localhost:8000
JWT_SECRET=demo-secret-minimo-32-caracteres-aqui
JOB_SECRET=demo-job-secret-ok
```

### 1.2 Levantar infraestructura

```bash
# Desde la raíz del proyecto
docker-compose up -d

# Verificar que levantaron
docker ps  # debe mostrar postgres y redis corriendo
```

### 1.3 Migración y seed

```bash
cd api
bunx prisma migrate dev --name init
bunx prisma generate
bunx prisma db seed
```

El seed carga automáticamente:
- Zona de riesgo **88/100** en Av. El Sol 235, SJL
- Incidente CRITICAL activo en esa zona (para mostrar el mapa desde el inicio)
- Incidente MODERATE en Miraflores
- Usuario demo `seed-user-001`

### 1.4 Frontend — panel web (web/)

```bash
cd web
bun install
bun run dev   # levanta en localhost:5173
```

El panel web debe mostrar:
- Mapa de Lima con los incidentes del seed visibles
- Zona de riesgo marcada en SJL (color según riskScore: 88 = rojo)
- Sidebar con filtros por distrito y severidad

### 1.5 Mobile — app Flutter

```bash
cd mobile
flutter pub get
flutter run   # conectar dispositivo físico o emulador
```

Tener lista **al menos una cuenta Firebase** para reportar desde la app.

### 1.6 ML (opcional para demo)

```bash
cd ml
uv sync
uv run uvicorn src.main:app --reload --port 8000
```

Si no está listo, el API funciona igual — el ML call es fail-open (no bloquea nada).

---

## 2. Script de demo — secuencia recomendada

### Escena 1 — "El mapa en tiempo real" (2 min)

**Qué mostrás:**
1. Abrir el panel web → el mapa ya tiene un incidente CRITICAL en SJL (del seed)
2. Mostrar la zona de riesgo 88/100 destacada en rojo
3. Explicar: "Este score lo genera nuestro modelo ML basado en historial de incidentes"

**Qué decís:**
> "El panel web muestra en tiempo real los incidentes activos en Lima. Esta zona en San Juan de Lurigancho tiene score de riesgo 88 sobre 100, con hora pico predicha a las 13:00 — hora de salida de clases."

---

### Escena 2 — "El Threshold Engine" (5 min)

Esta es la parte técnica más importante. Necesitás 3 cuentas Firebase distintas o limpiar Redis entre reportes.

**Preparación previa:**
```bash
# Limpiar thresholds de Redis antes de la demo (no toca incidentes en DB)
redis-cli DEL "threshold:-11.980:-77.005:ROBBERY"
```

**Reporte 1** — desde la app móvil, cuenta A:
```
Tipo: ROBBERY
Lat: -11.9800, Lng: -77.0050
Formulario: personsInvolved=2-3, weapon=false, stillInArea=true
```

Mostrar en el panel web: **nada aparece todavía**

> "El primer reporte se guarda internamente pero no se publica. Necesitamos corroboración."

**Reporte 2** — desde la app móvil, cuenta B (dentro de 15 min):
```
Mismas coordenadas ± 50m
Tipo: ROBBERY
```

Mostrar en el panel web: **aparece incidente LOW** (sin push todavía)

> "Con dos reportes en la misma zona en 15 minutos, el sistema publica el incidente como severidad BAJA."

**Reporte 3** — cuenta C:
```
Mismas coordenadas
weapon: true
```

Mostrar en el panel web: **incidente sube a MODERATE** + notificación push en el teléfono

> "El tercer reporte escala a MODERADO y dispara notificaciones push a todos los ciudadanos en el distrito."

**Reporte 4 y 5** — simular con Swagger:
- Abrir `http://localhost:3000/docs`
- POST `/incidents/reports` con token Firebase válido
- Mostrar que al 5to reporte escala a **CRITICAL**

---

### Escena 3 — "WebSocket en tiempo real" (2 min)

Tener el panel web y la app móvil visibles simultáneamente.

1. Desde la app → reportar incidente nuevo
2. En el panel web → el pin aparece **sin recargar la página**

> "El mapa se actualiza en tiempo real via WebSocket. Las autoridades ven los incidentes al instante sin necesidad de refrescar."

---

### Escena 4 — "Botón de pánico" (2 min)

Desde la app móvil:
1. Activar botón de pánico
2. Mostrar en consola/logs: URLs firmadas de GCS generadas
3. El audio empieza a grabarse en chunks
4. Desactivar la sesión

> "El botón de pánico graba audio cifrado directamente a Google Cloud Storage. El servidor nunca toca el contenido — solo genera las URLs de subida."

---

### Escena 5 — "Anonimato (Ley 29733)" (1 min)

Abrir `http://localhost:3000/docs` → GET `/incidents` → ejecutar

Mostrar la respuesta JSON en pantalla grande y señalar:
- ✅ `id`, `type`, `severity`, `district`, `reportCount`
- ❌ No aparece `userId`, `firebaseUid`, `email`, coordenadas exactas del reportante

> "Por diseño y por ley, ningún endpoint expone la identidad del ciudadano que reportó."

---

### Escena 6 — "Confirm/Deny Waze-style" (1 min)

Desde la app:
1. Ver un incidente activo
2. Tocar "Confirmar — sigue ahí"
3. Mostrar en el panel web que `confirmCount` sube

> "Los ciudadanos cercanos pueden validar si el incidente sigue activo, igual que Waze."

---

## 3. Solución de problemas frecuentes

### Redis pierde los thresholds entre reinicios

```bash
# Redis por defecto no persiste en Docker — agregar esto al docker-compose.yml
redis:
  command: redis-server --appendonly yes
```

### El incidente del seed ya expiró

```bash
# Re-ejecutar el seed (usa upsert, no duplica)
cd api && bunx prisma db seed
```

### El mapa no muestra la zona de riesgo

Verificar que `GET /zones/-11.9800/-77.0050/risk` retorna `riskScore: 88`.
Si retorna `riskScore: 0`, el seed no se ejecutó correctamente.

### Push notifications no llegan

Para la demo es suficiente mostrar el log del servidor. El push real requiere:
1. Token FCM registrado via `POST /auth/device-token`
2. App en background en dispositivo físico (no funciona en emulador)

### Rate limit bloqueando reportes de demo

```bash
# Limpiar rate limits (no borra incidentes)
redis-cli KEYS "rate:report:*" | xargs redis-cli DEL
```

---

## 4. Checklist día de demo

```
[ ] docker-compose up -d  (postgres + redis corriendo)
[ ] bunx prisma db seed   (datos demo cargados)
[ ] bun run dev           (API en :3000)
[ ] bun run dev           (Web en :5173)
[ ] flutter run           (App en dispositivo)
[ ] GET /health → { status: "ok" }
[ ] GET /incidents → lista con incidente demo de SJL
[ ] GET /zones/-11.9800/-77.0050/risk → riskScore: 88
[ ] Panel web muestra mapa con incidente en SJL
[ ] Redis limpio de thresholds anteriores
[ ] 3 cuentas Firebase listas para la secuencia de reportes
[ ] Dispositivo físico para push notifications
[ ] Modo avión OFF en el dispositivo
[ ] localhost:3000/docs abierto para mostrar Swagger
```

---

## 5. Coordenadas de referencia para la demo

| Lugar | Lat | Lng | Uso |
|-------|-----|-----|-----|
| Av. El Sol 235 (universidad) | -11.9800 | -77.0050 | Centro de la demo |
| 50m al norte | -11.9795 | -77.0050 | Reporte 2 |
| 50m al este | -11.9800 | -77.0045 | Reporte 3 |
| 80m al sur | -11.9807 | -77.0050 | Reporte 4 |
| 70m al oeste | -11.9800 | -77.0057 | Reporte 5 |

Todas caen en el mismo bucket de ~100m → se acumulan en el mismo threshold.
