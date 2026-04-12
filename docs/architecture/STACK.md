# STACK.md — Stack Tecnológico AlertaYa

## RESUMEN EJECUTIVO

| Capa | Tecnología | Versión mínima |
|------|-----------|----------------|
| App móvil | Flutter + Dart | Flutter 3.19 / Dart 3.3 |
| Panel web (autoridades) | React + TypeScript | React 18 / TS 5.4 |
| API Gateway / Backend | Node.js + Express | Node 20 LTS |
| Microservicio ML | Python + FastAPI | Python 3.11 |
| Base de datos principal | PostgreSQL + PostGIS | Postgres 16 |
| Caché / Rate limiting | Redis | Redis 7 |
| Autenticación | Firebase Auth | SDK v10 |
| Push notifications | Firebase Cloud Messaging (FCM) | |
| Storage (grabaciones pánico) | Google Cloud Storage | |
| Infra / Deploy | Google Cloud Run + Docker | |
| CI/CD | GitHub Actions | |
| Mapas (móvil) | flutter_map + OpenStreetMap | |
| Mapas (web) | Leaflet.js | v1.9 |
| Rutas | OpenRouteService API | Gratuito |

## GESTORES DE DEPENDENCIAS

| Servicio | Gestor | Motivo |
|----------|--------|--------|
| `mobile/` | `flutter pub` / `dart pub` | Gestor nativo del SDK — sin alternativas en Flutter |
| `web/` | **Bun** | Instalación y build hasta 10× más rápido que npm; compatible con el ecosistema npm |
| `api/` | **npm** | Node.js LTS — compatibilidad garantizada con todas las dependencias de Firebase Admin |
| `ml/` | **uv** | Resolución de dependencias Python hasta 100× más rápida que pip; lock file determinístico |

> Regla: no mezclar gestores dentro de un mismo servicio.
| ORM | Prisma (Node.js) | v5 |

---

## APP MÓVIL — Flutter

### Gestión de estado
```
flutter_bloc: ^8.1.5        # BLoC pattern — estado de features
get_it: ^7.6.7              # Service locator / DI
injectable: ^2.3.2          # Code gen para DI
```

### Navegación
```
go_router: ^13.2.0          # Navegación declarativa con deep links
```

### Red y datos
```
dio: ^5.4.3                 # HTTP client con interceptors
retrofit: ^4.1.0            # Generador de clientes HTTP tipados
json_annotation: ^4.8.1
json_serializable: ^6.7.1
```

### Mapas e incidentes
```
flutter_map: ^6.1.0         # Mapa con tiles OSM
latlong2: ^0.9.0            # Coordenadas
geolocator: ^11.0.0         # GPS y permisos
geocoding: ^3.0.0           # Geocodificación inversa
```

### Notificaciones y pánico
```
firebase_messaging: ^14.9.2    # FCM push
flutter_local_notifications: ^17.2.1
record: ^5.1.0                 # Grabación audio/video
flutter_foreground_task: ^6.1.6 # Android Foreground Service (pánico)
speech_to_text: ^6.6.0         # Palabra clave de voz
```

### Seguridad
```
flutter_secure_storage: ^9.0.0  # Almacenamiento seguro de tokens
local_auth: ^2.1.8              # Biometría
crypto: ^3.0.3                  # AES-256 local antes de upload
```

### Almacenamiento local
```
hive_flutter: ^1.1.0          # Base de datos local para modo offline
hive: ^2.2.3
hive_generator: ^2.0.1
```

### Firebase
```
firebase_core: ^2.30.1
firebase_auth: ^4.19.5
cloud_firestore: ^4.17.3     # Solo para estado en tiempo real de incidentes
firebase_storage: ^11.7.5    # Subida de grabaciones cifradas
```

### UI
```
cached_network_image: ^3.3.1
shimmer: ^3.0.0              # Loading states
lottie: ^3.1.0               # Animaciones (solo splash y onboarding)
flutter_svg: ^2.0.10         # Logo y íconos en SVG
```

### Dev / Code gen
```
build_runner: ^2.4.8
freezed: ^2.4.7             # Inmutabilidad en modelos de dominio
freezed_annotation: ^2.4.1
mocktail: ^1.0.3            # Mocking en tests
bloc_test: ^9.1.7
```

---

## PANEL WEB — React + TypeScript

### Core
```json
"react": "^18.3.0",
"react-dom": "^18.3.0",
"typescript": "^5.4.0",
"vite": "^5.2.0"
```

### Routing
```json
"@tanstack/react-router": "^1.114.0"  // Type-safe routing con beforeLoad guards — sin wrappers de componente
```

### Estado
```json
"zustand": "^5.0.0"         // Client state — auth, UI state — API minimalista, sin boilerplate RTK
// Server state: @tanstack/react-query (ya incluido)
```

### UI / Componentes
```json
"@radix-ui/react-dialog": "^1.0.5",
"@radix-ui/react-dropdown-menu": "^2.0.6",
"@radix-ui/react-select": "^2.0.0",
"@radix-ui/react-toast": "^1.1.5",
"clsx": "^2.1.1",
"tailwind-merge": "^2.3.0"
```

### Estilos
```json
"tailwindcss": "^3.4.0",     // Con tokens de marca en tailwind.config.ts
"@tailwindcss/forms": "^0.5.7"
```

### Mapas
```json
"leaflet": "^1.9.4",
"react-leaflet": "^4.2.1",
"@types/leaflet": "^1.9.8"
```

### Gráficas
```json
"recharts": "^2.12.0"       // Barras y líneas para estadísticas
```

### Red
```json
"axios": "^1.6.8",
"@tanstack/react-query": "^5.32.0"   // Server state + caché
```

### Formularios
```json
"react-hook-form": "^7.51.0",
"zod": "^3.23.0",
"@hookform/resolvers": "^3.3.4"
```

### Exportación
```json
"jspdf": "^2.5.1",
"xlsx": "^0.18.5"
```

### Dev
```json
"eslint": "^8.57.0",
"prettier": "^3.2.5",
"vitest": "^1.5.0",
"@testing-library/react": "^15.0.0"
```

---

## BACKEND — Node.js + Express

### Core
```json
"express": "^4.19.0",
"typescript": "^5.4.0",
"ts-node": "^10.9.2"
```

### Seguridad y Auth
```json
"firebase-admin": "^12.1.0",      // Verificar tokens Firebase
"helmet": "^7.1.0",               // Headers de seguridad
"express-rate-limit": "^7.2.0",   // Rate limiting por IP
"ioredis": "^5.3.2",             // Redis para threshold engine
"bcryptjs": "^2.4.3",
"jsonwebtoken": "^9.0.2"
```

### Base de datos
```json
"@prisma/client": "^5.13.0",
"prisma": "^5.13.0"
```

### Validación
```json
"zod": "^3.23.0",
"express-zod-api": "^19.0.0"
```

### Comunicación en tiempo real
```json
"socket.io": "^4.7.5"             // WebSocket para mapa en vivo
```

### Notificaciones
```json
"firebase-admin": "^12.1.0"       // FCM server-side
```

### Storage
```json
"@google-cloud/storage": "^7.10.0"
```

### Utils
```json
"winston": "^3.13.0",             // Logging estructurado
"cors": "^2.8.5",
"compression": "^1.7.4",
"uuid": "^9.0.1"
```

### Dev y testing
```json
"vitest": "^1.6.0",               // Test runner unificado con web/ — mismo toolchain Vite
"@vitest/coverage-v8": "^1.6.0",
"supertest": "^7.0.0",
"@types/express": "^4.17.21",
"nodemon": "^3.1.0"
```

---

## MICROSERVICIO ML — Python + FastAPI

```
fastapi==0.115.0
uvicorn==0.30.0
scikit-learn==1.5.0
pandas==2.2.0
numpy==1.26.0
xgboost==2.0.3
prophet==1.1.5
psycopg2-binary==2.9.9
sqlalchemy==2.0.30
joblib==1.4.0
pydantic==2.7.0
python-dotenv==1.0.1
pytest==8.2.0
httpx==0.27.0                 # Test de endpoints FastAPI
```

---

## INFRAESTRUCTURA

### Docker
- Un `Dockerfile` por servicio
- `docker-compose.yml` en raíz para desarrollo local
- Servicios: `api`, `ml`, `web`, `postgres`, `redis`

### Variables de entorno
- `.env.example` en cada servicio — nunca commitear `.env`
- Secrets en Google Secret Manager en producción

### Puertos locales (docker-compose)
| Servicio | Puerto |
|----------|--------|
| API Node.js | 3000 |
| FastAPI ML | 8000 |
| React Web | 5173 |
| PostgreSQL | 5432 |
| Redis | 6379 |

### Google Cloud
- **Cloud Run** para API y ML (serverless, escala a 0)
- **Cloud SQL** para PostgreSQL con PostGIS
- **Cloud Storage** para grabaciones AES-256
- **Secret Manager** para variables sensibles
- **Cloud Pub/Sub** para eventos async entre servicios
