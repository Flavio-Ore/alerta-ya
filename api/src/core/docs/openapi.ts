export const openApiSpec = {
  openapi: '3.0.3',
  info: {
    title: 'AlertaYa API',
    version: '1.0.0',
    description: `
## AlertaYa — Backend API

Sistema de alertas ciudadanas en tiempo real para Lima Metropolitana.

### Autenticación

La mayoría de endpoints requieren un **Firebase ID Token** en el header:
\`\`\`
Authorization: Bearer <firebase-id-token>
\`\`\`
Obtenerlo con el SDK de Firebase Auth en la app móvil o el panel web.

### Autoridades

Los endpoints marcados con 🔒 **Autoridad** requieren además el **Firebase custom claim** \`authority: true\`.
Solo cuentas configuradas por el administrador tienen ese claim.

### Anonimato (Ley N° 29733)

Ningún endpoint expone datos de identidad del reportante:
- ❌ \`userId\`, \`firebaseUid\`, \`email\`, nombre, IP
- ✅ tipo de incidente, zona, severidad, conteos agregados, formulario sin vincular

### WebSocket (tiempo real)

Conectarse con \`socket.io-client\` a la raíz del servidor.

**Rooms automáticos al conectar:**
- \`Lima\` — todos los incidentes de Lima Metropolitana
- \`district:{nombre}\` — incidentes del distrito del usuario
- \`prox:{lat2}:{lng2}\` — incidentes en radio ~1km (grid de 2 decimales)

**Eventos emitidos por el servidor:**
| Evento | Cuándo | Payload |
|--------|--------|---------|
| \`incident:new\` | Threshold alcanzado | \`PublicIncidentDTO\` |
| \`incident:updated\` | Severidad o estado cambiado | \`PublicIncidentDTO\` |
| \`alert:confirm-request\` | Primer reporte en zona | \`{ zoneLabel, type }\` |

**Evento para actualizar sala al moverse:**
\`\`\`js
socket.emit('room:update', { lat: -12.12, lng: -77.03, district: 'Miraflores' })
\`\`\`
`,
    contact: {
      name: 'Tech Lead',
      email: 'nakea.studio@gmail.com',
    },
  },
  servers: [
    { url: 'http://localhost:3000', description: 'Desarrollo local' },
  ],
  tags: [
    { name: 'Health', description: 'Estado del servidor' },
    { name: 'Auth', description: 'Token FCM para push notifications' },
    { name: 'Incidents', description: 'Reportes ciudadanos e incidentes publicados' },
    { name: 'Zones', description: 'Zonas de riesgo predictivo (ML)' },
    { name: 'Panic', description: 'Botón de pánico con grabación cifrada' },
    { name: 'Notifications', description: 'Historial de alertas del usuario (tab Alertas)' },
  ],
  components: {
    securitySchemes: {
      FirebaseAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'Firebase ID Token',
        description: 'Token obtenido de Firebase Auth SDK',
      },
    },
    schemas: {
      // ─── Incident ────────────────────────────────────────────────────────────
      PublicIncidentDTO: {
        type: 'object',
        required: ['id', 'type', 'severity', 'status', 'lat', 'lng', 'district', 'reportCount', 'expiresAt'],
        properties: {
          id: { type: 'string', format: 'uuid' },
          type: { type: 'string', enum: ['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS'] },
          severity: { type: 'string', enum: ['LOW', 'MODERATE', 'CRITICAL'] },
          status: { type: 'string', enum: ['ACTIVE', 'IN_ATTENTION', 'CLOSED'] },
          lat: { type: 'number', example: -12.1167 },
          lng: { type: 'number', example: -77.0372 },
          district: { type: 'string', example: 'Miraflores' },
          confirmCount: { type: 'integer', example: 2 },
          denyCount: { type: 'integer', example: 0 },
          reportCount: { type: 'integer', example: 3 },
          expiresAt: { type: 'string', format: 'date-time' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
          unitAssigned: { type: 'string', nullable: true },
          feedback: {
            type: 'string',
            nullable: true,
            example: 'Unidad policial en camino al sector',
            description: 'Mensaje de la autoridad visible al ciudadano. null hasta que la autoridad lo actualice.',
          },
        },
      },
      ReportEvidenceDTO: {
        type: 'object',
        description: 'Evidencia de un reporte individual. Nunca incluye userId ni datos de identidad.',
        properties: {
          formData: {
            type: 'object',
            description: 'Respuestas del formulario dinámico',
            example: { weapon: 'firearm', injured: 'yes', stillInArea: true },
          },
          mediaUrls: {
            type: 'array',
            items: { type: 'string', format: 'uri' },
            description: 'URLs de Firebase Storage (gs://) con fotos/video subidos por el reportante',
          },
        },
      },
      PublicIncidentDetailDTO: {
        allOf: [
          { $ref: '#/components/schemas/PublicIncidentDTO' },
          {
            type: 'object',
            properties: {
              weaponReports: { type: 'integer', example: 2, description: 'Reportes que marcaron arma de fuego' },
              injuredReports: { type: 'integer', example: 1, description: 'Reportes que marcaron heridos visibles' },
              stillHereReports: { type: 'integer', example: 3, description: 'Reportes que marcaron que el agresor sigue en el lugar' },
              evidence: {
                type: 'array',
                items: { $ref: '#/components/schemas/ReportEvidenceDTO' },
                description: 'Evidencia agregada por reporte — sin vincular a identidad del reportante',
              },
            },
          },
        ],
      },
      PaginatedIncidents: {
        type: 'object',
        properties: {
          items: { type: 'array', items: { $ref: '#/components/schemas/PublicIncidentDTO' } },
          total: { type: 'integer', example: 42 },
          page: { type: 'integer', example: 1 },
        },
      },
      // ─── Forms ───────────────────────────────────────────────────────────────
      RobberyForm: {
        type: 'object',
        required: ['personsInvolved', 'weapon', 'stillInArea', 'fleeDirection'],
        properties: {
          personsInvolved: { type: 'string', enum: ['1', '2-3', '4-5', 'more-than-5', 'unknown'] },
          weapon: { type: 'boolean', description: '¿Portaba arma de fuego?' },
          stillInArea: { type: 'boolean', description: '¿El agresor sigue en el área?' },
          fleeDirection: { type: 'string', enum: ['north', 'south', 'east', 'west', 'unknown'] },
        },
      },
      AccidentForm: {
        type: 'object',
        required: ['injured', 'vehicleCount', 'blocksTraffic', 'medicalPresent'],
        properties: {
          injured: { type: 'boolean', description: '¿Hay heridos?' },
          vehicleCount: { type: 'integer', minimum: 1, maximum: 10 },
          blocksTraffic: { type: 'boolean', description: '¿Bloquea el tráfico?' },
          medicalPresent: { type: 'boolean', description: '¿Ya hay personal médico en el lugar?' },
        },
      },
      // ─── Zone ────────────────────────────────────────────────────────────────
      ZoneRiskDTO: {
        type: 'object',
        properties: {
          district: { type: 'string', example: 'La Victoria' },
          riskScore: { type: 'integer', minimum: 0, maximum: 100, example: 72 },
          predictedHour: { type: 'integer', minimum: 0, maximum: 23, example: 22 },
          reason: { type: 'string', example: 'no_data', description: 'Presente solo cuando no hay datos ML para la zona' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      // ─── Panic ───────────────────────────────────────────────────────────────
      PublicPanicSessionDTO: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          startedAt: { type: 'string', format: 'date-time' },
          endedAt: { type: 'string', format: 'date-time', nullable: true },
          status: { type: 'string', enum: ['ACTIVE', 'DEACTIVATED', 'TIMEOUT'] },
          uploadUrls: {
            type: 'array',
            items: { type: 'string', format: 'uri' },
            description: 'URLs firmadas de GCS para subir chunks de audio. PUT con Content-Type: audio/webm. Expiran en 5 min.',
          },
        },
      },
      // ─── Notifications ───────────────────────────────────────────────────────
      NotificationDTO: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          type: {
            type: 'string',
            enum: ['INCIDENT_NEW', 'INCIDENT_UPDATED', 'INCIDENT_STATUS_UPDATE', 'ZONE_RISK', 'PANIC_RESOLVED'],
          },
          title: { type: 'string', example: 'Tu reporte está siendo atendido' },
          body: { type: 'string', example: 'Incidente en Miraflores — "Unidad policial en camino"' },
          incidentId: { type: 'string', format: 'uuid', nullable: true },
          readAt: { type: 'string', format: 'date-time', nullable: true, description: 'null = no leída' },
          createdAt: { type: 'string', format: 'date-time' },
        },
      },
      PaginatedNotifications: {
        type: 'object',
        properties: {
          items: { type: 'array', items: { $ref: '#/components/schemas/NotificationDTO' } },
          total: { type: 'integer', example: 15 },
          unreadCount: { type: 'integer', example: 3, description: 'Total de no leídas — usar para el badge del tab' },
        },
      },
      // ─── Errors ──────────────────────────────────────────────────────────────
      ErrorResponse: {
        type: 'object',
        properties: {
          error: {
            type: 'object',
            properties: {
              message: { type: 'string', example: 'Token de autenticación requerido' },
              code: { type: 'integer', example: 401 },
            },
          },
        },
      },
    },
  },
  paths: {
    // ─── Health ──────────────────────────────────────────────────────────────
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Estado del servidor',
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    status: { type: 'string', example: 'ok' },
                    service: { type: 'string', example: 'alertaya-api' },
                    timestamp: { type: 'string', format: 'date-time' },
                  },
                },
              },
            },
          },
        },
      },
    },

    // ─── Auth ────────────────────────────────────────────────────────────────
    '/auth/device-token': {
      post: {
        tags: ['Auth'],
        summary: 'Registrar token FCM del dispositivo',
        description: `
Registra o actualiza el token FCM para recibir push notifications.

**Cuándo llamarlo:** justo después de un login exitoso con Firebase Auth.

**Comportamiento:** si el token ya existe (mismo dispositivo), actualiza el distrito. No crea duplicados.

El token queda en **PostgreSQL** (persistente) y en **Redis** (índice rápido por zona).
        `,
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['token', 'district'],
                properties: {
                  token: { type: 'string', description: 'Token FCM generado por Firebase Messaging', example: 'fGHijk...' },
                  district: { type: 'string', description: 'Último distrito conocido del usuario', example: 'Miraflores' },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Token registrado', content: { 'application/json': { schema: { type: 'object', properties: { ok: { type: 'boolean', example: true } } } } } },
          401: { description: 'Token Firebase requerido', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
      delete: {
        tags: ['Auth'],
        summary: 'Eliminar token FCM al hacer logout',
        description: 'Elimina el token del dispositivo. El usuario deja de recibir push hasta el próximo login.',
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['token'],
                properties: {
                  token: { type: 'string', example: 'fGHijk...' },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Token eliminado', content: { 'application/json': { schema: { type: 'object', properties: { ok: { type: 'boolean', example: true } } } } } },
          401: { description: 'Token Firebase requerido', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },

    // ─── Incidents ───────────────────────────────────────────────────────────
    '/incidents': {
      get: {
        tags: ['Incidents'],
        summary: 'Listar incidentes activos',
        description: 'Retorna incidentes ACTIVE no expirados. **Público, sin autenticación.**',
        parameters: [
          { name: 'severity', in: 'query', schema: { type: 'string', enum: ['LOW', 'MODERATE', 'CRITICAL'] } },
          { name: 'district', in: 'query', schema: { type: 'string' }, example: 'Miraflores' },
          { name: 'since', in: 'query', schema: { type: 'string', format: 'date-time' } },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'pageSize', in: 'query', schema: { type: 'integer', default: 20, maximum: 100 } },
        ],
        responses: {
          200: { description: 'OK', content: { 'application/json': { schema: { $ref: '#/components/schemas/PaginatedIncidents' } } } },
          400: { description: 'Query params inválidos', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/{id}': {
      get: {
        tags: ['Incidents'],
        summary: 'Detalle de un incidente',
        description: 'Incluye estadísticas agregadas + evidencia por reporte. **Nunca expone identidad del reportante.** Público.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          200: { description: 'OK', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicIncidentDetailDTO' } } } },
          404: { description: 'Incidente no encontrado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/{id}/status': {
      patch: {
        tags: ['Incidents'],
        summary: '🔒 Autoridad — Actualizar estado con feedback al ciudadano',
        description: `
**Solo autoridades** (Firebase custom claim \`authority: true\`).

Actualiza el estado del incidente y envía una notificación a todos los ciudadanos que reportaron.

**Ciclo de vida del incidente:**
\`\`\`
ACTIVE → IN_ATTENTION → CLOSED
\`\`\`

**Qué dispara:**
1. Actualiza \`status\` y \`feedback\` en la base de datos
2. Emite \`incident:updated\` por WebSocket (el mapa actualiza el pin en tiempo real)
3. Crea una notificación en la tabla \`notifications\` para cada usuario que reportó
4. La app mobile muestra: *"Tu reporte está siendo atendido — {feedback}"*
        `,
        security: [{ FirebaseAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['status'],
                properties: {
                  status: { type: 'string', enum: ['IN_ATTENTION', 'CLOSED'] },
                  feedback: {
                    type: 'string',
                    maxLength: 200,
                    description: 'Mensaje visible al ciudadano. Opcional pero recomendado.',
                    example: 'Unidad policial en camino al sector',
                  },
                },
              },
              examples: {
                attending: {
                  summary: 'Marcar como en atención',
                  value: { status: 'IN_ATTENTION', feedback: 'Unidad policial en camino al sector' },
                },
                closed: {
                  summary: 'Cerrar incidente',
                  value: { status: 'CLOSED', feedback: 'Situación controlada, zona despejada' },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Estado actualizado', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicIncidentDTO' } } } },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          403: { description: 'Acceso restringido a autoridades', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          404: { description: 'Incidente no encontrado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          409: { description: 'El incidente ya está cerrado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/reports': {
      post: {
        tags: ['Incidents'],
        summary: 'Crear un reporte ciudadano',
        description: `
Crea un reporte anónimo. La identidad del reportante **nunca se expone** en ningún endpoint.

**Flujo de media (Firebase Storage):**
1. La app sube la foto/video directo a Firebase Storage
2. La app recibe las URLs (\`gs://\`) del archivo subido
3. Las URLs se incluyen en \`mediaUrls[]\` de este endpoint

**Lógica del Threshold Engine:**
| Reportes | Ventana | Resultado |
|----------|---------|-----------|
| 1 | — | Guardado internamente. Emite mini-alert por WebSocket a usuarios cercanos |
| 2 | 15 min | Publicado como LOW (sin push) |
| 3+ | 15 min | MODERATE + push FCM a zona |
| 5+ | 20 min | CRITICAL + push + alerta policial |

**Escalaciones por formulario:**
- 3+ con arma de fuego → forzar CRITICAL
- 3+ con heridos → CRITICAL + alerta policial
- 3+ "sigue en el área" → extender expiración 30 min

**Rate limiting:** máximo 3 reportes/hora por cuenta.
        `,
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['lat', 'lng', 'type', 'formData'],
                properties: {
                  lat: { type: 'number', minimum: -90, maximum: 90, example: -12.1167, description: 'Lima: [-12.28, -11.77]' },
                  lng: { type: 'number', minimum: -180, maximum: 180, example: -77.0372, description: 'Lima: [-77.17, -76.78]' },
                  type: { type: 'string', enum: ['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS'] },
                  formData: { oneOf: [{ $ref: '#/components/schemas/RobberyForm' }, { $ref: '#/components/schemas/AccidentForm' }] },
                  mediaUrls: {
                    type: 'array',
                    items: { type: 'string', format: 'uri' },
                    maxItems: 5,
                    description: 'URLs de Firebase Storage (gs://). La app sube primero, luego manda las URLs.',
                  },
                },
              },
              examples: {
                robbery: {
                  summary: 'Robo a mano armada',
                  value: {
                    lat: -12.1167, lng: -77.0372, type: 'ROBBERY',
                    formData: { personsInvolved: '2-3', weapon: true, stillInArea: false, fleeDirection: 'north' },
                    mediaUrls: ['gs://alertaya-1b963.appspot.com/evidence/abc.jpg'],
                  },
                },
                accident: {
                  summary: 'Accidente de tránsito',
                  value: {
                    lat: -12.0853, lng: -77.0508, type: 'ACCIDENT',
                    formData: { injured: true, vehicleCount: 2, blocksTraffic: true, medicalPresent: false },
                    mediaUrls: [],
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Reporte guardado — no alcanzó threshold todavía (primer reporte en zona)',
            content: { 'application/json': { schema: { type: 'object', properties: { incident: { type: 'null' } } } } },
          },
          201: {
            description: 'Incidente publicado — threshold alcanzado',
            content: { 'application/json': { schema: { type: 'object', properties: { incident: { $ref: '#/components/schemas/PublicIncidentDTO' } } } } },
          },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          422: { description: 'Coordenadas fuera de Lima Metropolitana', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          429: { description: 'Límite de 3 reportes/hora alcanzado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/zone-confirmations': {
      post: {
        tags: ['Incidents'],
        summary: 'Responder mini-alert de zona',
        description: `
Responde al evento WebSocket \`alert:confirm-request\` que llega cuando hay un primer reporte cerca.

**Peso:** una confirmación "yes" suma 0.5 al threshold (menos que un reporte completo para evitar manipulación).

**Cooldown:** un usuario no puede responder la misma zona más de una vez cada 30 minutos.
        `,
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['zoneKey', 'response'],
                properties: {
                  zoneKey: { type: 'string', description: 'Clave de zona del threshold. Se recibe en el evento alert:confirm-request', example: 'threshold:-12.117:-77.037:ROBBERY' },
                  response: { type: 'string', enum: ['yes', 'no'] },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Respuesta registrada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    ok: { type: 'boolean' },
                    reason: { type: 'string', enum: ['cooldown'], description: 'Presente cuando ok=false' },
                  },
                },
              },
            },
          },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/{id}/confirm': {
      post: {
        tags: ['Incidents'],
        summary: 'Confirmar o desmentir un incidente (Waze-style)',
        description: 'Cada usuario puede votar una sola vez. Si `denyCount > confirmCount + 5` el incidente se cierra automáticamente.',
        security: [{ FirebaseAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['vote'],
                properties: {
                  vote: { type: 'string', enum: ['yes', 'no'], description: '"yes" = sigue ahí, "no" = ya no está' },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Incidente actualizado', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicIncidentDTO' } } } },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          409: { description: 'Ya votaste en este incidente', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },

    // ─── Zones ───────────────────────────────────────────────────────────────
    '/zones/{lat}/{lng}/risk': {
      get: {
        tags: ['Zones'],
        summary: 'Score de riesgo de una zona',
        description: 'Busca la zona más cercana (~1km) con predicción ML. Si no hay datos devuelve `riskScore: 0, reason: "no_data"`. **Público.**',
        parameters: [
          { name: 'lat', in: 'path', required: true, schema: { type: 'number' }, example: -12.1167 },
          { name: 'lng', in: 'path', required: true, schema: { type: 'number' }, example: -77.0372 },
        ],
        responses: {
          200: { description: 'OK', content: { 'application/json': { schema: { $ref: '#/components/schemas/ZoneRiskDTO' } } } },
          422: { description: 'Coordenadas fuera de Lima Metropolitana', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },

    // ─── Panic ───────────────────────────────────────────────────────────────
    '/panic/sessions': {
      post: {
        tags: ['Panic'],
        summary: 'Activar sesión de pánico',
        description: `
Activa el botón de pánico. Devuelve **URLs firmadas de GCS** para subir audio cifrado directo desde el dispositivo.

- Máximo 6 URLs (6 bloques de 10 min = 60 min total)
- Cada URL expira en 5 minutos
- Subir cada chunk: \`PUT {url}\` con \`Content-Type: audio/webm\`
- Solo puede haber **una sesión activa** por usuario
- Las grabaciones se cifran **AES-256 antes de subir**
        `,
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['lat', 'lng'],
                properties: {
                  lat: { type: 'number', example: -12.1167 },
                  lng: { type: 'number', example: -77.0372 },
                },
              },
            },
          },
        },
        responses: {
          201: { description: 'Sesión iniciada', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicPanicSessionDTO' } } } },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          409: { description: 'Ya tenés una sesión de pánico activa', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/panic/sessions/{id}': {
      delete: {
        tags: ['Panic'],
        summary: 'Desactivar sesión de pánico',
        description: 'Solo el propietario puede desactivarla. La propiedad se verifica con el token Firebase, **nunca con datos del body.**',
        security: [{ FirebaseAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          200: { description: 'Sesión desactivada', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicPanicSessionDTO' } } } },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          403: { description: 'No sos el propietario de esta sesión', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          404: { description: 'Sesión no encontrada', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          409: { description: 'La sesión ya fue desactivada', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },

    // ─── Notifications ───────────────────────────────────────────────────────
    '/notifications': {
      get: {
        tags: ['Notifications'],
        summary: 'Historial de notificaciones del usuario',
        description: `
Alimenta el **tab "Alertas"** en la app mobile.

**\`unreadCount\`** siempre está presente en la respuesta — úsalo para el badge del tab sin necesidad de un request extra.

**Cuándo aparece una notificación aquí:**
- Nuevo incidente MODERATE/CRITICAL cerca del usuario
- Incidente escaló de severidad
- La autoridad actualizó el estado con feedback al usuario que reportó
        `,
        security: [{ FirebaseAuth: [] }],
        parameters: [
          { name: 'unreadOnly', in: 'query', schema: { type: 'boolean', default: false }, description: 'true = solo no leídas' },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'pageSize', in: 'query', schema: { type: 'integer', default: 20, maximum: 50 } },
        ],
        responses: {
          200: { description: 'OK', content: { 'application/json': { schema: { $ref: '#/components/schemas/PaginatedNotifications' } } } },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/notifications/read': {
      patch: {
        tags: ['Notifications'],
        summary: 'Marcar notificaciones como leídas',
        description: `
Dos modos:
- **Por IDs:** \`{ ids: ["uuid1", "uuid2"], all: false }\` — marcar las indicadas
- **Todas:** \`{ ids: [], all: true }\` — marcar todas las del usuario (botón "Limpiar todo")

Solo marca notificaciones del usuario autenticado — no hay riesgo de marcar las de otro usuario.
        `,
        security: [{ FirebaseAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  ids: { type: 'array', items: { type: 'string', format: 'uuid' }, default: [] },
                  all: { type: 'boolean', default: false },
                },
              },
              examples: {
                byIds: {
                  summary: 'Marcar por IDs',
                  value: { ids: ['550e8400-e29b-41d4-a716-446655440000'], all: false },
                },
                allRead: {
                  summary: 'Marcar todas como leídas',
                  value: { ids: [], all: true },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Notificaciones marcadas',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    ok: { type: 'boolean', example: true },
                    updated: { type: 'integer', example: 3, description: 'Cantidad de notificaciones actualizadas' },
                  },
                },
              },
            },
          },
          401: { description: 'No autenticado', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
  },
};
