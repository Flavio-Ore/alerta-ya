# AlertaYa — Equipo y Cronograma

## Equipo

| Avatar | Nombre      | Rol                      | Responsabilidad principal                                                          | Herramientas                                                                            |
| ------ | ----------- | ------------------------ | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| EL     | **Elena**   | Tech Lead · Backend · ML | Arquitectura general, API Node.js, FastAPI Python, Docker, CI/CD                   | Claude Code · Node.js · Bun · Python · PostgreSQL · Redis · Firebase Admin · Docker · FastAPI |
| FL     | **Flavio**  | Lead Web Panel           | Lidera el panel de autoridades en React — toma decisiones de frontend, guía a Jose | React · TypeScript · SQL · NoSQL · BaaS · JS                                            |
| JO     | **Jorge**   | Lead Mobile              | Lidera la app ciudadana en Flutter — auth, reporte de incidentes, integración API  | Flutter · Firebase · TypeScript · React · Python                                        |
| AN     | **Anthony** | Mobile Maps              | Mapas, rutas, capas de riesgo y notificaciones push en Flutter                     | Flutter · firebase_messaging · flutter_map · Frontend                                   |
| JE     | **Jose**    | Web Panel Dev            | Co-desarrolla el panel de autoridades junto a Flavio                               | React · TypeScript · Firebase · Frontend                                                |

### Pares de trabajo

```
Backend + ML  →  Elena  (Tech Lead)
Mobile        →  Jorge + Anthony
Web Panel     →  Flavio + Jose
```

---

## Stack de cada responsable

| Módulo                     | Responsable     | Tecnologías                                            |
| -------------------------- | --------------- | ------------------------------------------------------ |
| API REST + WebSocket       | Elena           | Node.js · Express · Socket.io · Prisma · PostgreSQL    |
| Auth middleware            | Elena           | Firebase Admin SDK                                     |
| Rate limiting              | Elena           | Redis                                                  |
| Threshold engine           | Elena           | Redis (2 reportes = LEVE, 3+ = MODERADO, 5+ = CRÍTICO) |
| ML — Verificación          | Elena           | Python · FastAPI · Isolation Forest (scikit-learn)     |
| ML — Predicción            | Elena           | Python · Random Forest · Prophet                       |
| CI/CD · Docker             | Elena           | GitHub Actions · Docker Compose · Cloud Run            |
| Panel web — arquitectura   | Flavio          | React · TanStack Router · TanStack Query · Zustand     |
| Panel web — UI             | Flavio + Jose   | shadcn/ui · Tailwind CSS · recharts                    |
| Panel web — auth 2FA       | Flavio          | Firebase Auth · TOTP                                   |
| Panel web — mapas          | Flavio          | Leaflet · react-leaflet                                |
| Panel web — export         | Jose            | jspdf · xlsx                                           |
| App móvil — arquitectura   | Jorge           | Flutter · Clean Architecture · injectable              |
| App móvil — auth           | Jorge           | Firebase Auth                                          |
| App móvil — reporte        | Jorge           | flutter_map · Dio · go_router                          |
| App móvil — mapas capas    | Anthony         | flutter_map · markers · severity layers                |
| App móvil — notificaciones | Anthony         | firebase_messaging · FCM                               |
| App móvil — pánico         | Jorge + Anthony | grabación, WebSocket, GCS upload                       |

---

## Cronograma — 8 Sprints · 16 Semanas

### Sprint 1 · Semanas 1–2 · Fundación y Auth

**Meta:** Todo el mundo puede correr el proyecto. Auth funcionando end-to-end.

| Quién   | Tarea            | Detalle                                                                         |
| ------- | ---------------- | ------------------------------------------------------------------------------- |
| Elena   | Setup infra      | Docker Compose corriendo (postgres + redis) · `.env.example` en cada servicio   |
| Elena   | API base         | `GET /health` · Express config · Firebase Admin SDK inicializado · `bun install` |
| Elena   | Auth middleware  | `verifyToken` · attach `req.user.uid` · **nunca exponer uid en respuestas**     |
| Elena   | Prisma schema    | Migraciones iniciales: User · Incident · Report · PanicSession · RiskZone       |
| Flavio  | Web auth         | Login con Firebase · ruta `/auth/login` · `beforeLoad` guard en TanStack Router |
| Flavio  | Layout base      | Sidebar + TopBar + estructura de rutas protegidas                               |
| Jose    | Página de login  | UI de la pantalla de login · form con react-hook-form + zod · manejo de errores |
| Jorge   | Flutter setup    | `flutter pub get` · `build_runner` · go_router · injectable configurado         |
| Jorge   | Mobile auth      | Firebase Auth en Flutter · pantalla login · guard de ruta                       |
| Anthony | flutter_map base | Mapa centrado en Lima · tiles OpenStreetMap · permisos de ubicación             |

---

### Sprint 2 · Semanas 3–4 · Incidentes Core

**Meta:** Crear y listar incidentes. El reporte del ciudadano llega y se guarda.

| Quién   | Tarea                | Detalle                                                                                       |
| ------- | -------------------- | --------------------------------------------------------------------------------------------- |
| Elena   | `POST /reports`      | Validar campos · guardar reporte anónimo · **nunca guardar userId en incidents**              |
| Elena   | Threshold engine     | Redis: `incidents:{zone}:{window}` · 2 reportes → LEVE · 3+ → MODERADO · 5+ → CRÍTICO         |
| Elena   | `GET /incidents`     | Filtros por severidad, zona, fecha · paginación · sin datos de identidad                      |
| Elena   | `GET /incidents/:id` | Detalle de incidente · sin uid del reportante                                                 |
| Flavio  | Dashboard skeleton   | Cards de estadísticas (Skeleton mientras carga) · lista de incidentes recientes               |
| Flavio  | Incidents list       | Tabla con shadcn/ui DataTable + `@tanstack/react-table` · filtros básicos                     |
| Jose    | Incident detail page | Página completa de detalle de incidente · consume `GET /incidents/:id` · layout con shadcn/ui |
| Jorge   | Flujo de reporte     | Formulario de reporte · selector de tipo (Robo, Accidente) · `POST /reports`                  |
| Jorge   | Confirmación         | Pantalla de éxito tras reportar · manejo de errores                                           |
| Anthony | Marcadores en mapa   | Pinchar incidentes en el mapa · distintos iconos por severidad                                |

---

### Sprint 3 · Semanas 5–6 · Tiempo Real

**Meta:** El panel web y la app reflejan cambios sin recargar.

| Quién   | Tarea                    | Detalle                                                                                                         |
| ------- | ------------------------ | --------------------------------------------------------------------------------------------------------------- |
| Elena   | WebSocket server         | Socket.io · room `Lima` · emit `incident:new` y `incident:updated`                                              |
| Elena   | ML — Isolation Forest    | `POST /ml/verify` · detección de reportes anómalos · score de confianza                                         |
| Elena   | Integración ML→API       | API llama al servicio ML al recibir reporte · aplica penalización si score < umbral                             |
| Flavio  | Socket.io cliente        | `socket.io-client` · suscribirse a `incident:new` · actualizar lista sin reload                                 |
| Flavio  | Toasts tiempo real       | `useToast()` al llegar incidente crítico · sonido de alerta                                                     |
| Jose    | Stats cards + Toasts     | Cards de métricas (total hoy, críticos, zonas activas) con Skeleton · integrar `useToast` para alertas críticas |
| Jorge   | WebSocket Flutter        | `socket_io_client` · escuchar eventos · actualizar estado del mapa                                              |
| Anthony | Live map updates         | Añadir/actualizar marcadores al recibir `incident:new` sin rebuild completo                                     |
| Anthony | Clustering de marcadores | Agrupar marcadores cercanos para no saturar el mapa                                                             |

---

### Sprint 4 · Semanas 7–8 · Features Avanzadas

**Meta:** Pánico, notificaciones push y detalle de incidente completo.

| Quién   | Tarea              | Detalle                                                                                       |
| ------- | ------------------ | --------------------------------------------------------------------------------------------- |
| Elena   | Panic API          | `POST /panic/start` · `POST /panic/stop` · upload chunks de audio a GCS                       |
| Elena   | Geofencing         | Detectar si incidente está dentro de Lima (`lat: [-12.28,-11.77]`, `lng: [-77.17,-76.78]`)    |
| Elena   | Rate limiting      | Redis: max 3 reportes/hora por usuario · falla abierta si Redis no disponible                 |
| Flavio  | Incident detail    | Sheet (panel lateral) con mapa embed, tipo, severidad, hora, zona — sin datos de identidad    |
| Flavio  | Filtros avanzados  | Filtrar por severidad + tipo + rango de fechas · Select + DatePicker shadcn/ui                |
| Jose    | Página Statistics  | Página de estadísticas completa · gráficos con shadcn/ui chart (recharts) · filtros por fecha |
| Jorge   | Panic button       | Botón en Flutter · grabación de audio · stream a API · UI de emergencia                       |
| Anthony | Push notifications | `firebase_messaging` · recibir alerta de incidente cercano · mostrar en foreground/background |

---

### Sprint 5 · Semanas 9–10 · ML Predicción + Zonas de Riesgo

**Meta:** El sistema predice zonas de riesgo. El mapa muestra capas de calor.

| Quién   | Tarea               | Detalle                                                                                       |
| ------- | ------------------- | --------------------------------------------------------------------------------------------- |
| Elena   | ML — Random Forest  | Modelo de predicción de riesgo por zona · features: hora, día, tipo, historial                |
| Elena   | ML — Prophet        | Serie temporal de incidentes · predicción para las próximas 24h                               |
| Elena   | `GET /risk-zones`   | Endpoint con zonas y nivel de riesgo calculado · actualización periódica                      |
| Flavio  | Página Predicciones | Gráfico de líneas (recharts/shadcn chart) con predicción 24h · tabla de zonas                 |
| Flavio  | Mapa de calor web   | Leaflet heatmap layer sobre incidentes históricos                                             |
| Jose    | Export completo     | Página de exportación · generar PDF con jspdf · Excel con xlsx · descarga real desde el panel |
| Jorge   | Risk overlay móvil  | Consumir `GET /risk-zones` · mostrar overlay de riesgo en mapa Flutter                        |
| Anthony | Heatmap Flutter     | Capa de calor sobre el mapa con datos de zonas de riesgo                                      |

---

### Sprint 6 · Semanas 11–12 · Integración y Tests

**Meta:** Cada servicio testeado. Integración completa verificada.

| Quién   | Tarea             | Detalle                                                                                      |
| ------- | ----------------- | -------------------------------------------------------------------------------------------- |
| Elena   | Tests API         | Vitest · unit tests para threshold engine y auth middleware · integration tests con BD real  |
| Elena   | Tests ML          | pytest · `test_verifier.py` · `test_predictor.py` · pytest-asyncio correctamente configurado |
| Elena   | Prisma migrations | Revisar y limpiar migraciones · seed de datos de prueba para Lima                            |
| Flavio  | Tests web         | Vitest + Testing Library · tests de componentes críticos (SeverityBadge, DataTable)          |
| Flavio  | Auth 2FA          | TOTP en Firebase · flujo de segundo factor para autoridades                                  |
| Jose    | Tests web         | Vitest + Testing Library · tests de páginas Statistics y Export · coverage básico            |
| Jorge   | Tests Flutter     | `flutter test` · tests de widgets para flujo de reporte                                      |
| Anthony | Tests de mapa     | Verificar marcadores, clustering y heatmap con datos reales de Lima                          |

---

### Sprint 7 · Semanas 13–14 · QA y Hardening

**Meta:** El sistema aguanta carga real. Sin datos de identidad expuestos. CI/CD verde.

| Quién   | Tarea                  | Detalle                                                                         |
| ------- | ---------------------- | ------------------------------------------------------------------------------- |
| Elena   | Auditoría de seguridad | Revisar TODOS los endpoints: ¿alguno expone uid? · CORS · headers de seguridad  |
| Elena   | CI/CD completo         | GitHub Actions: lint → test → docker build en api, web, ml, mobile              |
| Elena   | Performance API        | Índices PostgreSQL · queries lentas · caché con Redis                           |
| Flavio  | Web QA                 | Probar todos los flujos en Chrome, Firefox, Safari · corregir bugs visuales     |
| Flavio  | Error boundaries       | Manejo de errores en TanStack Query · mensajes de error con Toast               |
| Jose    | Polish y responsividad | Revisión visual completa del panel · correcciones CSS · responsividad en tablet |
| Jorge   | Mobile QA              | Testing en Android e iOS (simulador) · flujo completo ciudadano                 |
| Anthony | Maps performance       | Verificar performance con 100+ marcadores · optimizar rebuild del mapa          |

---

### Sprint 8 · Semanas 15–16 · Deploy y Demo

**Meta:** Sistema corriendo en Cloud Run. Demo grabada o en vivo lista.

| Quién   | Tarea                   | Detalle                                                                                      |
| ------- | ----------------------- | -------------------------------------------------------------------------------------------- |
| Elena   | Deploy Cloud Run        | API + ML en Cloud Run · Cloud SQL (PostgreSQL) · Memorystore (Redis)                         |
| Elena   | Variables de producción | Secrets en GCP · Firebase project prod vs dev                                                |
| Elena   | Demo data               | Script de seed con incidentes de Lima reales para la demo                                    |
| Flavio  | Build web producción    | `bun run build` · servir desde Cloud Run o CDN                                               |
| Flavio  | Checklist UX            | Recorrer todos los flujos del panel como autoridad real                                      |
| Jose    | Demo web + docs         | Recorrer todos los flujos del panel · documentar componentes clave · screenshots para README |
| Jorge   | Build APK demo          | `flutter build apk --release` · instalar en dispositivo para demo                            |
| Anthony | Demo en vivo            | Preparar escenario de demo: reportar incidente desde app → aparece en panel                  |

---

## Resumen de carga por persona

| Persona | Sprints más pesados     | Riesgo principal                                                         |
| ------- | ----------------------- | ------------------------------------------------------------------------ |
| Elena   | 1–5 (infra + ML)        | Cuello de botella: todos dependen de la API                              |
| Flavio  | 2–6 (panel completo)    | Lidera arquitectura frontend · coordina con Jose la división de features |
| Jorge   | 1–4 (móvil core)        | Flutter tiene curva — priorizar flujo básico antes que features          |
| Anthony | 3–5 (mapas + real-time) | flutter_map con real-time es complejo — empezar simple                   |
| Jose    | 2–8 (panel web)         | Par real de Flavio — se divide el panel en features completas            |

---

## Reglas del equipo

1. **Nadie bloquea a otro** — si una tarea depende de un endpoint de Elena, Elena deja un mock primero
2. **Identidad nunca expuesta** — Ley N° 29733: `userId` / `uid` nunca aparece en respuestas de la API
3. **Sin hardcodear hex** — siempre usar los tokens `ay-*` de Tailwind o las constantes de Flutter
4. **Un PR por feature** — branches cortas, PRs pequeños, revisar antes de mergear a `main`
5. **Cada uno entrega features completas** — no hay tareas de "apoyo" sin ownership real

---

## Convención de branches

```
main          →  producción estable
develop       →  integración continua
feature/EL-*  →  Elena
feature/FL-*  →  Flavio
feature/JO-*  →  Jorge
feature/AN-*  →  Anthony
feature/JE-*  →  Jose
```

Ejemplo: `feature/EL-threshold-engine`, `feature/FL-incidents-table`, `feature/JO-report-flow`
