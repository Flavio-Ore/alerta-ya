# AlertaYa — Historias de Usuario por Sprint

> Descomposición de las 10 HU del documento de análisis en items técnicos accionables.
> Responsables asignados según [TEAM.md](./TEAM.md).
> Estimaciones en horas siguiendo el patrón: BD simple 4h · BD complejo 12-16h · UI/formularios 6-12h · endpoints 6-8h · integraciones 8-12h · tests 4-6h.

## Leyenda

- **MoSCoW**: M = Must · S = Should · C = Could · W = Won't
- **Responsables**: EL = Elena · FL = Flavio · JO = Jorge · AN = Anthony · JE = Jose

---

## HU001 — Reportar incidente · RF02 · Sprint 2

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H1   | Reportar incidente| M      | H1-1    | Crear schema Prisma `Incident` y `Report` + migración                             | EL          | 8             |
|      |                   |        | H1-2    | Endpoint `POST /reports` con validación Zod (tipo, GPS, evidencia opcional)       | EL          | 8             |
|      |                   |        | H1-3    | Threshold engine Redis (2 → LEVE · 3+ → MODERADO · 5+ → CRÍTICO)                  | EL          | 8             |
|      |                   |        | H1-4    | Upload de evidencia (foto/audio/video) a GCS desde API                            | EL          | 8             |
|      |                   |        | H1-5    | Formulario Flutter: selector tipo incidente + captura GPS automática              | JO          | 12            |
|      |                   |        | H1-6    | Adjuntar evidencia desde cámara/galería (foto, audio, video)                      | JO          | 8             |
|      |                   |        | H1-7    | Integración `POST /reports` desde móvil con manejo de errores y timeout < 10s     | JO          | 6             |
|      |                   |        | H1-8    | Pantalla de confirmación de envío exitoso                                         | JO          | 4             |
|      |                   |        | H1-9    | Pruebas unitarias API (threshold engine + endpoint)                               | EL          | 4             |
|      |                   |        | H1-10   | Pruebas widget Flutter del flujo de reporte                                       | JO          | 4             |
|      |                   |        |         | **Total HU001**                                                                   |             | **70**        |

---

## HU002 — Mapa en tiempo real · RF08 · Sprint 2-3

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H2   | Mapa tiempo real  | M      | H2-1    | Endpoint `GET /incidents` con filtros (severidad, zona, fecha) + paginación       | EL          | 6             |
|      |                   |        | H2-2    | Servidor Socket.io con room `Lima` y eventos `incident:new` / `incident:updated`  | EL          | 8             |
|      |                   |        | H2-3    | Mapa base Flutter centrado en Lima con tiles OpenStreetMap                        | AN          | 6             |
|      |                   |        | H2-4    | Marcadores por incidente con iconos diferenciados por severidad                   | AN          | 8             |
|      |                   |        | H2-5    | Cliente `socket_io_client` Flutter — suscripción y actualización sin rebuild      | AN          | 8             |
|      |                   |        | H2-6    | Clustering de marcadores cercanos                                                 | AN          | 6             |
|      |                   |        | H2-7    | Tap en marcador → bottom sheet con info detallada del incidente                   | AN          | 6             |
|      |                   |        | H2-8    | Pruebas de marcadores y clustering con dataset Lima                               | AN          | 4             |
|      |                   |        |         | **Total HU002**                                                                   |             | **52**        |

---

## HU003 — Notificaciones Push · RF06 · Sprint 4

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H3   | Notificaciones    | M      | H3-1    | Setup Firebase Cloud Messaging en API (admin SDK)                                 | EL          | 6             |
|      |                   |        | H3-2    | Endpoints registro/borrado de device tokens (`POST/DELETE /device-tokens`)        | EL          | 4             |
|      |                   |        | H3-3    | Lógica de envío FCM al confirmar incidente cercano (< 3s)                         | EL          | 8             |
|      |                   |        | H3-4    | Persistencia de notificaciones en Postgres + endpoint `GET /notifications`        | EL          | 6             |
|      |                   |        | H3-5    | Integración `firebase_messaging` en Flutter (foreground/background/terminated)    | AN          | 8             |
|      |                   |        | H3-6    | UI de notificación con tipo + distancia al incidente                              | AN          | 6             |
|      |                   |        | H3-7    | Manejo de tap en notificación → navegar al detalle del incidente                  | AN          | 4             |
|      |                   |        | H3-8    | Pruebas de envío y recepción end-to-end                                           | AN          | 4             |
|      |                   |        |         | **Total HU003**                                                                   |             | **46**        |

---

## HU004 — Botón de pánico · RF09 · Sprint 4

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H4   | Pánico            | M      | H4-1    | Crear schema Prisma `PanicSession` (uid, inicio, fin, audio_url, ubicaciones)     | EL          | 4             |
|      |                   |        | H4-2    | Endpoints `POST /panic/start` y `POST /panic/stop`                                | EL          | 8             |
|      |                   |        | H4-3    | Upload de chunks de audio a GCS con cifrado AES-256                               | EL          | 12            |
|      |                   |        | H4-4    | Stream de ubicación por WebSocket durante sesión activa                           | EL          | 8             |
|      |                   |        | H4-5    | Configuración previa: PIN de seguridad + contacto de emergencia                   | JO          | 6             |
|      |                   |        | H4-6    | Botón de pánico en UI con activación rápida (long-press 3s)                       | JO          | 6             |
|      |                   |        | H4-7    | Grabación de audio en Flutter + envío de chunks a la API                          | JO          | 8             |
|      |                   |        | H4-8    | Captura y envío continuo de ubicación GPS                                         | JO          | 6             |
|      |                   |        | H4-9    | UI de modo emergencia (pantalla bloqueada, indicador de grabación)                | JO          | 6             |
|      |                   |        | H4-10   | Pruebas integradas del flujo completo                                             | JO          | 4             |
|      |                   |        |         | **Total HU004**                                                                   |             | **68**        |

---

## HU005 — Confirmación de incidentes · RF07 · Sprint 3

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H5   | Confirmación      | S      | H5-1    | Endpoint `PATCH /incidents/:id/confirm` con opciones `still_there` / `gone`       | EL          | 6             |
|      |                   |        | H5-2    | Lógica de actualización de estado y degradación de severidad por confirmaciones   | EL          | 6             |
|      |                   |        | H5-3    | Emisión de evento `incident:updated` por WebSocket                                | EL          | 4             |
|      |                   |        | H5-4    | Botones "Sigue ahí" / "Ya no está" en bottom sheet del mapa Flutter               | JO          | 6             |
|      |                   |        | H5-5    | Refresco automático del marcador en el mapa al recibir actualización              | AN          | 4             |
|      |                   |        | H5-6    | Pruebas unitarias del endpoint y de la lógica de degradación                      | EL          | 4             |
|      |                   |        |         | **Total HU005**                                                                   |             | **30**        |

---

## HU006 — Validación con IA · RF04 · Sprint 3

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H6   | Validación IA     | M      | H6-1    | Setup FastAPI service `ml/` con estructura Clean Architecture                     | EL          | 6             |
|      |                   |        | H6-2    | Dataset sintético de reportes Lima para entrenamiento                             | EL          | 8             |
|      |                   |        | H6-3    | Modelo Isolation Forest entrenado y serializado                                   | EL          | 12            |
|      |                   |        | H6-4    | Endpoint `POST /ml/verify` con respuesta < 5s                                     | EL          | 8             |
|      |                   |        | H6-5    | Integración API → ML al recibir reporte (llamada async)                           | EL          | 6             |
|      |                   |        | H6-6    | Penalización de severidad si score < umbral configurado                           | EL          | 4             |
|      |                   |        | H6-7    | Pruebas pytest del verifier con casos anómalos y normales                         | EL          | 6             |
|      |                   |        |         | **Total HU006**                                                                   |             | **50**        |

---

## HU007 — Geofencing · RF11 · Sprint 4

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H7   | Geofencing        | S      | H7-1    | Schema Prisma `RiskZone` con polígono PostGIS                                     | EL          | 4             |
|      |                   |        | H7-2    | Endpoint `GET /risk-zones` con zonas activas                                      | EL          | 6             |
|      |                   |        | H7-3    | Validación de coordenadas dentro de Lima (`lat: [-12.28,-11.77]`)                 | EL          | 4             |
|      |                   |        | H7-4    | Detección de entrada a zona de riesgo en Flutter (background location)            | AN          | 8             |
|      |                   |        | H7-5    | Envío de alerta local automática al cruzar geofence                               | AN          | 6             |
|      |                   |        | H7-6    | Overlay visual de zonas de riesgo sobre mapa Flutter                              | AN          | 6             |
|      |                   |        | H7-7    | Pruebas de detección con coordenadas simuladas                                    | AN          | 4             |
|      |                   |        |         | **Total HU007**                                                                   |             | **38**        |

---

## HU008 — Panel de gestión de incidentes · RF16 · Sprint 2-4

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H8   | Panel autoridades | M      | H8-1    | Setup React + TanStack Router + layout (sidebar + topbar)                         | FL          | 8             |
|      |                   |        | H8-2    | Auth Firebase con 2FA TOTP + guard `beforeLoad`                                   | FL          | 12            |
|      |                   |        | H8-3    | Página de login con react-hook-form + zod                                         | JE          | 6             |
|      |                   |        | H8-4    | Dashboard skeleton: stats cards (total, críticos, zonas activas)                  | JE          | 8             |
|      |                   |        | H8-5    | Lista de incidentes con shadcn DataTable + filtros por severidad/tipo/fecha       | FL          | 12            |
|      |                   |        | H8-6    | Página detalle de incidente con mapa embed (sin datos de identidad)               | JE          | 12            |
|      |                   |        | H8-7    | Mapa principal Leaflet con marcadores por severidad                               | FL          | 12            |
|      |                   |        | H8-8    | Cliente `socket.io-client` + toasts en tiempo real para incidentes críticos       | FL          | 8             |
|      |                   |        | H8-9    | Endpoint `PATCH /incidents/:id/status` para feedback de autoridad (ya existe)     | EL          | 4             |
|      |                   |        | H8-10   | Pruebas Vitest de componentes críticos (DataTable, SeverityBadge)                 | FL          | 6             |
|      |                   |        |         | **Total HU008**                                                                   |             | **88**        |

---

## HU009 — Predicción de riesgo · RF19 · Sprint 5

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H9   | Predicción riesgo | C      | H9-1    | Modelo Random Forest de riesgo por zona (features: hora, día, tipo, historial)    | EL          | 16            |
|      |                   |        | H9-2    | Modelo Prophet de serie temporal — predicción 24h                                 | EL          | 12            |
|      |                   |        | H9-3    | Endpoint `GET /risk-zones/predictions` con índice y horizonte temporal            | EL          | 8             |
|      |                   |        | H9-4    | Job periódico de re-cálculo de predicciones                                       | EL          | 6             |
|      |                   |        | H9-5    | Página "Predicciones" web con gráfico recharts                                    | FL          | 10            |
|      |                   |        | H9-6    | Tabla de zonas con índice de riesgo + ordenamiento                                | FL          | 6             |
|      |                   |        | H9-7    | Pruebas pytest de los modelos predictivos                                         | EL          | 6             |
|      |                   |        |         | **Total HU009**                                                                   |             | **64**        |

---

## HU010 — Comparador de rutas · RF14 · ⚠️ Sin sprint asignado

> **ATENCIÓN**: Esta HU no figura en el cronograma de [TEAM.md](./TEAM.md). Estimación tentativa — definir si entra al Sprint 5 (desplazando otra tarea) o queda como `Could` para post-MVP.

| Cod  | Módulo            | MoSCoW | Ítem    | Descripción                                                                       | Responsable | Estimado Hrs. |
| ---- | ----------------- | ------ | ------- | --------------------------------------------------------------------------------- | ----------- | ------------- |
| H10  | Comparador rutas  | C      | H10-1   | Integración con Google Directions API (o alternativa OSRM)                        | EL          | 8             |
|      |                   |        | H10-2   | Endpoint `POST /routes/compare` que devuelve N rutas con score de riesgo          | EL          | 12            |
|      |                   |        | H10-3   | Cálculo de score por ruta cruzando zonas de riesgo y heatmap                      | EL          | 8             |
|      |                   |        | H10-4   | UI Flutter: selector origen/destino con autocomplete                              | JO          | 8             |
|      |                   |        | H10-5   | Visualización de rutas alternativas en el mapa con color por nivel de riesgo      | AN          | 10            |
|      |                   |        | H10-6   | Selector de ruta + integración con app de navegación nativa                       | AN          | 6             |
|      |                   |        | H10-7   | Pruebas del endpoint con rutas conocidas de Lima                                  | EL          | 4             |
|      |                   |        |         | **Total HU010**                                                                   |             | **56**        |

---

## Resumen de carga total por persona

| Persona     | Horas estimadas | HU principales                     |
| ----------- | --------------- | ---------------------------------- |
| Elena (EL)  | 282             | HU001, HU002, HU003, HU004, HU005, HU006, HU007, HU009, HU010 (backend de todas) |
| Flavio (FL) | 82              | HU008, HU009                       |
| Jorge (JO)  | 90              | HU001, HU004, HU005, HU010         |
| Anthony (AN)| 94              | HU002, HU003, HU007, HU010         |
| Jose (JE)   | 26              | HU008                              |
| **Total**   | **574**         |                                    |

> Elena queda con carga muy alta (cuello de botella confirmado en TEAM.md). Considerar: (1) mover items de tests de API a otros responsables, (2) priorizar duro qué del Sprint 5 (HU009) entra al MVP.

---

## Mapeo HU → Sprint

| HU    | Sprint(s)   | Justificación                                                  |
| ----- | ----------- | -------------------------------------------------------------- |
| HU001 | 2           | Reporte es la base — depende de schema y threshold engine      |
| HU002 | 2-3         | Lista en S2, tiempo real con WebSocket en S3                   |
| HU003 | 4           | Push depende de incidentes ya operativos                       |
| HU004 | 4           | Pánico requiere infra de upload y WebSocket lista              |
| HU005 | 3           | Confirmación complementa el flujo de incidentes y tiempo real  |
| HU006 | 3           | ML verify se integra con el endpoint de reportes               |
| HU007 | 4           | Geofencing depende de zonas de riesgo y notificaciones         |
| HU008 | 2-4         | Panel evoluciona en paralelo con cada feature de backend       |
| HU009 | 5           | Predicción requiere histórico de incidentes                    |
| HU010 | ⚠️ definir   | No está en cronograma — decidir antes de Sprint 5              |
