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

### Anonimato (Ley N° 29733)
Ningún endpoint expone datos de identidad del reportante:
- ❌ userId, firebaseUid, email, nombre, IP
- ✅ tipo de incidente, zona, severidad, conteos agregados

### WebSocket (tiempo real)
Conectarse al servidor con \`socket.io-client\`. Al conectar, el cliente se une automáticamente al room **Lima**.

**Eventos emitidos por el servidor:**
- \`incident:new\` → nuevo incidente publicado
- \`incident:updated\` → incidente actualizado (severidad, confirmaciones)
`,
    contact: {
      name: 'Elena (Tech Lead)',
      email: 'nakea.studio@gmail.com',
    },
  },
  servers: [
    { url: 'http://localhost:3000', description: 'Desarrollo local' },
  ],
  tags: [
    { name: 'Health', description: 'Estado del servidor' },
    { name: 'Incidents', description: 'Gestión de incidentes y reportes ciudadanos' },
    { name: 'Zones', description: 'Zonas de riesgo predictivo' },
    { name: 'Panic', description: 'Botón de pánico — grabación y alerta de emergencia' },
  ],
  components: {
    securitySchemes: {
      FirebaseAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'Firebase ID Token',
        description: 'Token obtenido de Firebase Auth SDK en la app móvil o web',
      },
    },
    schemas: {
      PublicIncidentDTO: {
        type: 'object',
        required: ['id', 'type', 'severity', 'status', 'lat', 'lng', 'district', 'reportCount', 'expiresAt'],
        properties: {
          id: { type: 'string', format: 'uuid', example: 'a1b2c3d4-...' },
          type: {
            type: 'string',
            enum: ['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS'],
            example: 'ROBBERY',
          },
          severity: {
            type: 'string',
            enum: ['LOW', 'MODERATE', 'CRITICAL'],
            example: 'MODERATE',
          },
          status: {
            type: 'string',
            enum: ['ACTIVE', 'IN_ATTENTION', 'CLOSED'],
            example: 'ACTIVE',
          },
          lat: { type: 'number', example: -12.1167 },
          lng: { type: 'number', example: -77.0372 },
          district: { type: 'string', example: 'Miraflores' },
          confirmCount: { type: 'integer', example: 2 },
          denyCount: { type: 'integer', example: 0 },
          reportCount: { type: 'integer', example: 3 },
          expiresAt: { type: 'string', format: 'date-time' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
          unitAssigned: { type: 'string', nullable: true, example: null },
        },
      },
      PublicIncidentDetailDTO: {
        allOf: [
          { $ref: '#/components/schemas/PublicIncidentDTO' },
          {
            type: 'object',
            properties: {
              weaponReports: { type: 'integer', description: 'Cantidad de reportes que marcaron arma de fuego', example: 2 },
              injuredReports: { type: 'integer', description: 'Cantidad de reportes que marcaron heridos', example: 0 },
              stillHereReports: { type: 'integer', description: 'Cantidad de reportes que marcaron que el agresor sigue en el lugar', example: 1 },
            },
          },
        ],
      },
      RobberyForm: {
        type: 'object',
        required: ['personsInvolved', 'weapon', 'stillInArea', 'fleeDirection'],
        properties: {
          personsInvolved: {
            type: 'string',
            enum: ['1', '2-3', '4-5', 'more-than-5', 'unknown'],
          },
          weapon: { type: 'boolean', description: '¿Portaba arma de fuego?' },
          stillInArea: { type: 'boolean', description: '¿El agresor sigue en el área?' },
          fleeDirection: {
            type: 'string',
            enum: ['north', 'south', 'east', 'west', 'unknown'],
          },
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
      ZoneRiskDTO: {
        type: 'object',
        properties: {
          district: { type: 'string', example: 'La Victoria' },
          riskScore: { type: 'integer', minimum: 0, maximum: 100, example: 72 },
          predictedHour: { type: 'integer', minimum: 0, maximum: 23, description: 'Hora de mayor riesgo predicha por el modelo ML', example: 22 },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      PublicPanicSessionDTO: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          startedAt: { type: 'string', format: 'date-time' },
          endedAt: { type: 'string', format: 'date-time', nullable: true },
          lat: { type: 'number' },
          lng: { type: 'number' },
          status: { type: 'string', enum: ['ACTIVE', 'DEACTIVATED', 'TIMEOUT'] },
          uploadUrls: {
            type: 'array',
            items: { type: 'string', format: 'uri' },
            description: 'URLs firmadas de GCS para subir chunks de audio (PUT, 5min TTL, audio/webm)',
          },
        },
      },
      PaginatedIncidents: {
        type: 'object',
        properties: {
          items: { type: 'array', items: { $ref: '#/components/schemas/PublicIncidentDTO' } },
          total: { type: 'integer' },
          page: { type: 'integer' },
        },
      },
      ErrorResponse: {
        type: 'object',
        properties: {
          error: {
            type: 'object',
            properties: {
              message: { type: 'string' },
              code: { type: 'integer' },
            },
          },
        },
      },
    },
  },
  paths: {
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
    '/incidents': {
      get: {
        tags: ['Incidents'],
        summary: 'Listar incidentes activos',
        description: 'Retorna incidentes ACTIVE no expirados. Público, sin autenticación.',
        parameters: [
          { name: 'severity', in: 'query', schema: { type: 'string', enum: ['LOW', 'MODERATE', 'CRITICAL'] } },
          { name: 'district', in: 'query', schema: { type: 'string' }, example: 'Miraflores' },
          { name: 'since', in: 'query', schema: { type: 'string', format: 'date-time' }, description: 'Filtrar por fecha de creación' },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'pageSize', in: 'query', schema: { type: 'integer', default: 20, maximum: 100 } },
        ],
        responses: {
          200: {
            description: 'Lista paginada de incidentes',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/PaginatedIncidents' } } },
          },
          400: { description: 'Query params inválidos', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/incidents/{id}': {
      get: {
        tags: ['Incidents'],
        summary: 'Detalle de un incidente',
        description: 'Incluye estadísticas agregadas de respuestas del formulario. Nunca expone identidad del reportante.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          200: {
            description: 'Detalle del incidente',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicIncidentDetailDTO' } } },
          },
          404: { description: 'Incidente no encontrado' },
        },
      },
    },
    '/incidents/reports': {
      post: {
        tags: ['Incidents'],
        summary: 'Crear un reporte ciudadano',
        description: `
Crea un reporte anónimo. La identidad del reportante **nunca se expone** en ningún endpoint.

**Lógica del Threshold Engine (Redis):**
| Reportes | Ventana | Resultado |
|----------|---------|-----------|
| 1 | — | Guardado internamente, no publicado |
| 2 | 15 min | Publicado como LOW, sin push |
| 3+ | 15 min | MODERATE + push a zona |
| 5+ | 20 min | CRITICAL + push + alerta policial |

**Escalaciones por formulario (sin esperar IA):**
- 3+ reportes con arma → forzar CRITICAL
- 3+ reportes con heridos → CRITICAL + alerta policial
- 3+ "sigue en el área" → extender expiración 30 min

**Rate limiting:** máximo 3 reportes por hora por cuenta.
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
                  lat: { type: 'number', example: -12.1167, description: 'Latitud Lima: [-12.28, -11.77]' },
                  lng: { type: 'number', example: -77.0372, description: 'Longitud Lima: [-77.17, -76.78]' },
                  type: { type: 'string', enum: ['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS'] },
                  formData: {
                    oneOf: [
                      { $ref: '#/components/schemas/RobberyForm' },
                      { $ref: '#/components/schemas/AccidentForm' },
                    ],
                  },
                },
              },
              examples: {
                robbery: {
                  summary: 'Reporte de robo',
                  value: {
                    lat: -12.1167, lng: -77.0372, type: 'ROBBERY',
                    formData: { personsInvolved: '2-3', weapon: true, stillInArea: false, fleeDirection: 'north' },
                  },
                },
                accident: {
                  summary: 'Reporte de accidente',
                  value: {
                    lat: -12.0853, lng: -77.0508, type: 'ACCIDENT',
                    formData: { injured: true, vehicleCount: 2, blocksTraffic: true, medicalPresent: false },
                  },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Reporte guardado (no alcanzó threshold — incidente no publicado aún)', content: { 'application/json': { schema: { type: 'object', properties: { incident: { type: 'null' } } } } } },
          201: { description: 'Incidente publicado', content: { 'application/json': { schema: { type: 'object', properties: { incident: { $ref: '#/components/schemas/PublicIncidentDTO' } } } } } },
          401: { description: 'Token Firebase requerido' },
          422: { description: 'Coordenadas fuera de Lima Metropolitana' },
          429: { description: 'Límite de 3 reportes/hora alcanzado' },
        },
      },
    },
    '/incidents/{id}/confirm': {
      post: {
        tags: ['Incidents'],
        summary: 'Confirmar o desmentir un incidente (Waze-style)',
        description: 'Cada usuario puede votar una sola vez. Si los rechazos superan las confirmaciones por 5+, el incidente se cierra.',
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
          409: { description: 'Ya votaste en este incidente' },
        },
      },
    },
    '/zones/{lat}/{lng}/risk': {
      get: {
        tags: ['Zones'],
        summary: 'Score de riesgo de una zona',
        description: 'Busca la zona de riesgo más cercana (radio 1km) usando el modelo ML de predicción. Público.',
        parameters: [
          { name: 'lat', in: 'path', required: true, schema: { type: 'number' }, example: -12.1167 },
          { name: 'lng', in: 'path', required: true, schema: { type: 'number' }, example: -77.0372 },
        ],
        responses: {
          200: {
            description: 'Score de riesgo de la zona',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/ZoneRiskDTO' } } },
          },
          422: { description: 'Coordenadas fuera de Lima Metropolitana' },
        },
      },
    },
    '/panic/sessions': {
      post: {
        tags: ['Panic'],
        summary: 'Activar sesión de pánico',
        description: `
Activa el botón de pánico. Retorna **URLs firmadas de GCS** para subir chunks de audio directamente desde el dispositivo.

- Máximo 6 URLs (6 bloques de 10 min = 60 min)
- Cada URL expira en 5 minutos
- Upload: \`PUT {url}\` con \`Content-Type: audio/webm\`
- Solo puede haber **una sesión activa** por usuario
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
          201: {
            description: 'Sesión iniciada con URLs de upload',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicPanicSessionDTO' } } },
          },
          409: { description: 'Ya tenés una sesión de pánico activa' },
        },
      },
    },
    '/panic/sessions/{id}': {
      delete: {
        tags: ['Panic'],
        summary: 'Desactivar sesión de pánico',
        description: 'Solo el propietario de la sesión puede desactivarla. La propiedad se verifica con el token Firebase, nunca con datos del body.',
        security: [{ FirebaseAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          200: { description: 'Sesión desactivada', content: { 'application/json': { schema: { $ref: '#/components/schemas/PublicPanicSessionDTO' } } } },
          403: { description: 'No sos el propietario de esta sesión' },
          404: { description: 'Sesión no encontrada' },
          409: { description: 'La sesión ya fue desactivada' },
        },
      },
    },
  },
};
