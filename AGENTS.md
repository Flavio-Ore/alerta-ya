# AGENTS.md — AlertaYa Project Guide

> Este archivo es la fuente de verdad para Codex.
> Léelo completo antes de escribir una sola línea de código.
> Todos los documentos referenciados están en `/docs/`.

---

## 1. QUÉ ES ESTE PROYECTO

**AlertaYa** — App ciudadana de seguridad en tiempo real para Lima, Perú.
- **App móvil** (Flutter) para ciudadanos: reportar incidentes, recibir alertas, botón de pánico
- **Panel web** (React) para autoridades: supervisar incidentes, asignar unidades, exportar estadísticas
- **Backend** (Node.js + Python ML) con Firebase, PostgreSQL/PostGIS, Redis
- **MVP limitado** a Lima Metropolitana — ver restricciones en `/docs/architecture/CONSTRAINTS.md`

---

## 2. DOCUMENTOS DE REFERENCIA — LEER EN ESTE ORDEN

```
docs/
├── architecture/
│   ├── STACK.md              ← Stack tecnológico completo y justificación
│   ├── STRUCTURE.md          ← Estructura de carpetas de cada servicio
│   ├── DATA_MODELS.md        ← Esquemas de BD y modelos de datos
│   └── CONSTRAINTS.md        ← Restricciones de negocio y técnicas del MVP
├── design/
│   ├── BRAND.md              ← Tokens de marca: colores, tipografía, logo
│   ├── NAVIGATION.md         ← Arquitectura de navegación móvil y web
│   └── SCREENS.md            ← Inventario de pantallas por sistema
└── rules/
    ├── CODING_STANDARDS.md   ← Convenciones de código para todo el proyecto
    ├── UI_RULES.md           ← Reglas UI/UX no negociables
    └── SECURITY_RULES.md     ← Reglas de seguridad y privacidad (críticas)
```

---

## 3. REGLAS GLOBALES — NUNCA ROMPER

### Arquitectura
- **Clean Architecture** en todos los servicios: domain → application → infrastructure → presentation
- **Nunca** importar infraestructura directamente desde domain
- **Nunca** poner lógica de negocio en controllers, widgets o componentes UI
- Cada feature es un módulo independiente — sin cross-imports entre features
- **Inyección de dependencias** siempre: ningún servicio se instancia directamente en UI

### Código
- Leer `docs/rules/CODING_STANDARDS.md` antes de escribir cualquier archivo
- Nombres en **inglés** para código (variables, funciones, clases, archivos)
- Comentarios y strings de UI en **español** (la app es para Lima)
- Sin `any` en TypeScript — tipado estricto siempre
- Sin `dynamic` en Dart salvo casos muy justificados con comentario
- Tests unitarios para toda la lógica de dominio — no opcional

### Seguridad (CRÍTICO)
- Leer `docs/rules/SECURITY_RULES.md` ANTES de tocar auth, reportes o pánico
- **Nunca** exponer la identidad del reportante en ningún endpoint público
- **Nunca** almacenar datos sensibles sin cifrar (AES-256 para grabaciones)
- **Nunca** hacer logging de datos personales

### UI
- Leer `docs/rules/UI_RULES.md` antes de crear cualquier widget o componente
- **Sin gradientes**, sin sombras decorativas, sin más de 2 colores en el símbolo
- Tokens de color desde `docs/design/BRAND.md` — nunca hardcodear hex en código
- Bottom nav móvil: exactamente 5 ítems, pánico en el centro

---

## 4. CONTEXTO DE IDENTIDAD VISUAL

### El símbolo oficial de AlertaYa

El logo es una **campana de alerta azul con ondas de sonido ámbar** que emanan desde arriba.
Concepto: Alerta Ciudadana (campana) + Inmediatez/Velocidad (ondas expansivas).

```
Símbolo:     Campana sólida #1B3A6B con ondas concéntricas #F5A623 arriba
Logotipo:    "Alerta" en DM Sans Medium #0D1B2A + "Ya" en DM Sans ExtraBold #F5A623
Versión neg: Campana blanca + ondas blancas sobre fondo #0D1B2A
```

### Archivos de logo — dónde están en el proyecto

```
assets/
├── shared/
│   ├── logo/
│   │   ├── alertaya-isotipo.svg          ← Campana + ondas (cuadrado, 1024×1024)
│   │   ├── alertaya-logo-horizontal.svg  ← Isotipo + texto horizontal
│   │   ├── alertaya-logo-dark.svg        ← Versión negativa (sobre fondos oscuros)
│   │   └── alertaya-logo-mono.svg        ← Monocromático (1 color)
│   └── icons/
│       └── ...
├── mobile/                               ← Copiados/referenciados desde Flutter
│   ├── images/
│   │   └── logo/                         ← Rasterizados para app store
│   └── icons/
│       └── app_icon.png                  ← 1024×1024 para Play Store / App Store
└── web/
    └── public/
        ├── favicon.ico                   ← 32×32 de la campana
        ├── logo192.png                   ← PWA icon
        └── logo512.png                   ← PWA icon grande
```

### Reglas de uso del logo
- Campana: `#1B3A6B` (Azul Noche) — nunca cambiar
- Ondas: `#F5A623` (Ámbar Alerta) — nunca cambiar
- Máximo 2 colores en el símbolo — nunca agregar más
- Sin gradientes en ninguna versión
- Reconocible a 24px de tamaño mínimo
- "Alerta" Medium + "Ya" ExtraBold — siempre, sin excepciones

---

## 5. ESTRUCTURA DE ASSETS EN CADA SERVICIO

### Flutter (`mobile/`)
```
mobile/
└── assets/
    ├── images/
    │   └── logo/
    │       ├── alertaya_isotipo.svg
    │       ├── alertaya_logo_horizontal.svg
    │       └── alertaya_logo_dark.svg
    └── icons/
        └── (íconos de UI propios del sistema — NO del logo)
```
Declarar en `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/logo/
    - assets/icons/
```
Usar con `flutter_svg`:
```dart
SvgPicture.asset('assets/images/logo/alertaya_isotipo.svg', width: 48)
```

### React Web (`web/`)
```
web/
└── public/
    ├── favicon.ico
    ├── logo192.png
    ├── logo512.png
    └── assets/
        └── logo/
            ├── alertaya-isotipo.svg
            ├── alertaya-logo-horizontal.svg
            └── alertaya-logo-dark.svg
```
Usar en componentes:
```tsx
// En el sidebar oscuro del panel autoridades
<img src="/assets/logo/alertaya-logo-dark.svg" alt="AlertaYa" height={32} />

// En navbar claro
<img src="/assets/logo/alertaya-logo-horizontal.svg" alt="AlertaYa" height={32} />
```

---

## 6. GESTORES DE PAQUETES Y COMANDOS

> Cada servicio usa su gestor específico. No mezclar.

| Servicio | Gestor | Comando de instalación |
|----------|--------|----------------------|
| `mobile/` | `flutter pub` | `flutter pub get` |
| `web/` | **bun** | `bun install` |
| `api/` | **bun** | `bun install` |
| `ml/` | **uv** | `uv sync` |

### Comandos por servicio

```bash
# ─── FLUTTER (mobile/) ───────────────────────────────────────
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run

# ─── REACT WEB (web/) ────────────────────────────────────────
bun install
bun run dev          # Dev server en :5173
bun run build        # Build de producción
bun run lint
bun test

# ─── NODE.JS API (api/) ──────────────────────────────────────
bun install
bun run dev             # bun --watch en :3000 (TypeScript nativo)
bun run build           # Compila TypeScript → dist/
bun run lint
bun test
bun run prisma:generate  # Generar Prisma client
bun run prisma:migrate   # Aplicar migraciones
bun run prisma:validate  # Validar schema

# ─── PYTHON ML (ml/) ─────────────────────────────────────────
uv sync                                    # Instala deps + dev group
uv run uvicorn src.main:app --reload --port 8000
uv run pytest --tb=short
uv add <paquete>                           # Agrega dep a pyproject.toml
uv add --dev <paquete>                     # Agrega dep de desarrollo
uv lock                                    # Regenera uv.lock

# ─── DOCKER (dev local — todos los servicios) ────────────────
cp api/.env.example api/.env      # Rellenar antes de levantar
cp ml/.env.example ml/.env
docker-compose up --build         # Primera vez
docker-compose up                 # Veces siguientes
docker-compose down -v            # Detener y limpiar volúmenes
```

### Notas importantes
- `web/` y `api/` usan **bun** — NO usar `npm install` en esos directorios
- `ml/` usa **uv** — NO usar `pip install` directamente
- Los archivos `.env` NUNCA se commitean — solo `.env.example`
- Antes de `docker-compose up`, crear los `.env` desde `.env.example`

---

## 7. FLUJO DE TRABAJO ESPERADO

1. Leer el documento de referencia relevante antes de implementar
2. Crear la estructura de carpetas según `docs/architecture/STRUCTURE.md`
3. Implementar desde domain hacia afuera (domain → usecase → repo → infra → UI)
4. Agregar tests unitarios junto con la implementación, no después
5. Verificar que no se violan las restricciones de `CONSTRAINTS.md`
