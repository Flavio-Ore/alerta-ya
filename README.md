# AlertaYa

App ciudadana de seguridad en tiempo real para Lima, Perú.

Ciudadanos reportan incidentes desde el celular. Autoridades los supervisan en tiempo real desde un panel web. Un motor de ML verifica reportes y predice zonas de riesgo.

---

## Arquitectura

```
alertaya/
├── mobile/     Flutter — App ciudadana (iOS + Android)
├── web/        React — Panel de autoridades (solo web)
├── api/        Node.js + Express — Backend y WebSocket
└── ml/         Python + FastAPI — Verificación y predicción ML
```

**Bases de datos:** PostgreSQL 16 + PostGIS · Redis 7  
**Auth:** Firebase Auth (ciudadanos) + 2FA (autoridades)  
**Deploy:** Google Cloud Run + Docker  

---

## Requisitos previos

Instalar estas herramientas antes de ejecutar cualquier servicio:

| Herramienta | Versión mínima | Instalación |
|-------------|---------------|-------------|
| Docker + Docker Compose | Docker 24+ | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Flutter SDK | 3.19+ | [flutter.dev/install](https://docs.flutter.dev/get-started/install) |
| Node.js | 20 LTS | [nodejs.org](https://nodejs.org/) |
| Bun | 1.1+ | `curl -fsSL https://bun.sh/install \| bash` |
| Python | 3.11+ | [python.org](https://www.python.org/downloads/) |
| uv | latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

---

## Setup inicial (primera vez)

```bash
# 1. Clonar el repo
git clone <repo-url>
cd alertaya

# 2. Crear los archivos de entorno (NUNCA commitear .env)
cp api/.env.example api/.env
cp ml/.env.example ml/.env
cp web/.env.example web/.env
cp mobile/.env.example mobile/.env

# 3. Rellenar las variables en cada .env
#    (Firebase keys, DB credentials, GCS bucket, etc.)

# 4. Generar el lockfile de Bun (requerido para el build de Docker)
cd web && bun install && cd ..
```

---

## Flujo de desarrollo recomendado

> Este es el workflow que usa el equipo día a día. Da hot-reload real en todos los servicios de código.

**Paso 1 — Levantar solo la infraestructura con Docker:**

```bash
docker compose up postgres redis
```

Postgres y Redis corren en contenedores. No necesitás instalarlos localmente.

**Paso 2 — Correr cada servicio de código en su propia terminal:**

```bash
# Terminal 1 — API (hot-reload nativo con Bun)
cd api
bun install
bun run prisma:generate
bun run prisma:migrate               # solo la primera vez
bun run dev

# Terminal 2 — Web (Vite HMR instantáneo)
cd web
bun install
bun run dev

# Terminal 3 — ML (uvicorn --reload)
cd ml
uv sync
uv run uvicorn src.main:app --reload --port 8000
```

**Puertos locales:**

| Servicio | URL |
|----------|-----|
| Panel web (autoridades) | http://localhost:5173 |
| API REST + WebSocket | http://localhost:3000 |
| ML FastAPI | http://localhost:8000 |
| API health check | http://localhost:3000/health |
| ML health check | http://localhost:8000/health |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

> **¿Por qué no todo en Docker para desarrollo?**  
> Los Dockerfiles del proyecto están pensados para producción — generan builds compilados sin hot-reload.
> Correr postgres y redis en Docker, y el código fuente local, te da lo mejor de los dos mundos:
> infraestructura sin instalar nada, y cambios que se reflejan instantáneamente.

---

## Ejecutar todo con Docker (producción / demo)

Usa esto para levantar el stack completo como en producción, o para mostrarle el proyecto a alguien sin configurar nada:

```bash
# Primera vez — compila todas las imágenes
docker compose up --build

# Veces siguientes (usa el cache)
docker compose up

# Solo algunos servicios
docker compose up postgres redis api

# Ver logs de un servicio en tiempo real
docker compose logs -f api

# Detener todo
docker compose down

# Detener y eliminar volúmenes (base de datos limpia)
docker compose down -v
```

> Las dependencias se instalan automáticamente dentro de cada imagen durante el `--build`.
> No necesitás correr `bun install`, `npm install` ni `uv pip install` a mano.

---

## Ejecutar servicios individualmente

### App móvil — Flutter

```bash
cd mobile
flutter pub get
flutter run                    # Emulador o dispositivo conectado
flutter run -d chrome          # Web (para desarrollo)
flutter analyze --fatal-infos  # Lint
flutter test                   # Tests unitarios
```

### Panel web — React + Bun

```bash
cd web
bun install
bun run dev       # http://localhost:5173
bun run build     # Build de producción
bun run lint
bun test
```

### API Backend — Node.js + Bun

```bash
cd api
bun install

# Configurar base de datos
bun run prisma:generate
bun run prisma:migrate   # Primera migración (nombre: init)

bun run dev    # http://localhost:3000 con hot-reload (TypeScript nativo)
bun run build  # Compilar TypeScript → dist/
bun test       # Tests con Vitest
bun run lint
```

### Microservicio ML — Python + uv

```bash
cd ml
uv sync                  # Instala todas las deps (incluye dev group)

# Dev server con hot-reload
uv run uvicorn src.main:app --reload --port 8000

# Tests
uv run pytest --tb=short

# Agregar una dependencia nueva
uv add <paquete>         # dep de producción → pyproject.toml
uv add --dev <paquete>   # dep de desarrollo (tests, lint)
```

---

## Estructura del proyecto

```
alertaya/
│
├── mobile/                     # Flutter app (ciudadano)
│   ├── lib/
│   │   ├── app/                # Router, DI (get_it + injectable)
│   │   ├── core/               # Colores, tipografía, widgets base
│   │   └── features/           # auth, map, report, panic, risk, profile
│   └── pubspec.yaml
│
├── web/                        # Panel React (autoridades)
│   ├── src/
│   │   ├── core/               # Constantes, lib (axios, react-query), componentes base
│   │   └── features/           # auth, dashboard, incidents, predictions, statistics, export
│   └── package.json
│
├── api/                        # Node.js backend
│   ├── src/
│   │   ├── core/               # Config, middleware (auth, rate-limit, errors)
│   │   └── features/           # incidents, panic, notifications, geofencing
│   └── prisma/schema.prisma    # Modelos de BD
│
├── ml/                         # Python ML microservice
│   └── src/
│       ├── core/               # Config, database
│       └── features/           # verification (Isolation Forest), prediction (RF + Prophet)
│
├── docs/                       # Documentación de arquitectura y reglas
│   ├── architecture/           # STACK.md, STRUCTURE.md, DATA_MODELS.md, CONSTRAINTS.md
│   ├── design/                 # BRAND.md, NAVIGATION.md, SCREENS.md
│   └── rules/                  # CODING_STANDARDS.md, UI_RULES.md, SECURITY_RULES.md
│
├── docker-compose.yml          # Dev local — todos los servicios
├── .github/workflows/          # CI/CD (api, mobile, ml)
└── CLAUDE.md                   # Guía para Claude Code
```

---

## Variables de entorno

Cada servicio tiene un `.env.example` con todas las variables documentadas.

| Servicio | Archivo |
|----------|---------|
| API | `api/.env.example` |
| ML | `ml/.env.example` |
| Web | `web/.env.example` |
| Mobile | `mobile/.env.example` |

**Variables críticas para funcionar:**
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` — Firebase Admin (API)
- `DATABASE_URL` — PostgreSQL con PostGIS
- `REDIS_URL` — Redis para rate limiting
- `GCS_BUCKET_NAME` — Google Cloud Storage para grabaciones de pánico
- `JWT_SECRET` — mínimo 32 caracteres

---

## Restricciones importantes del MVP

- Zona piloto: **solo Lima Metropolitana** (`lat: [-12.28, -11.77]`, `lng: [-77.17, -76.78]`)
- Formulario dinámico MVP: solo **Robo/Asalto** y **Accidente de Tránsito**
- Panel web: **solo para autoridades** — ciudadanos no tienen acceso
- Un reporte solo **no se publica**: mínimo 2 reportes independientes en 15 min para aparecer en el mapa
- **Identidad del reportante**: nunca expuesta — cumplimiento Ley N° 29733

Ver `docs/architecture/CONSTRAINTS.md` para la lista completa.

---

## Convenciones de código

- **Idioma del código**: inglés (variables, funciones, clases, archivos)
- **Idioma de la UI y comentarios**: español (la app es para Lima)
- **Colores**: siempre desde constantes — nunca hardcodear hex
- **Arquitectura**: Clean Architecture en todos los servicios (domain → application → infrastructure → presentation)
- **Tests**: obligatorios para lógica de dominio

Ver `docs/rules/CODING_STANDARDS.md` para el detalle completo.

---

## CI/CD

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci-api.yml` | Push/PR en `api/**` | lint → test → docker build |
| `ci-mobile.yml` | Push/PR en `mobile/**` | flutter analyze → flutter test |
| `ci-ml.yml` | Push/PR en `ml/**` | flake8 → pytest |

---

## Contacto del equipo

Para dudas sobre el proyecto, consultar primero `CLAUDE.md` y los documentos en `docs/`.
