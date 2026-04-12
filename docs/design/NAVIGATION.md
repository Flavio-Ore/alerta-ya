# NAVIGATION.md — Arquitectura de Navegación AlertaYa

---

## APP MÓVIL — Bottom Navigation (5 ítems)

### Estructura del Bottom Nav
```
[Mapa] [Alertas] [● PÁNICO] [Riesgo] [Perfil]
  1        2         3 (centro)    4       5
```

### Reglas de implementación
- El ítem de pánico (centro) es visualmente DISTINTO al resto:
  - Círculo rojo `#EF4444`, diámetro 44px, elevado por encima de la barra
  - Sin label de texto — solo el círculo con ícono de alerta/escudo
  - Borde blanco de 2px separándolo visualmente de la barra
- Ítems 1, 2, 4, 5: ícono + label, 9px
- Estado activo: ícono en `#F5A623`, label en `#F5A623`
- Estado inactivo: ícono y label en `#6B7A8D`
- Fondo de la barra: `#0D1B2A`
- Badge numérico en "Alertas" cuando hay notificaciones nuevas

### Rutas de navegación (go_router)

```dart
// Rutas principales (bottom nav)
/map           → MapPage (S04)
/alerts        → AlertsPage
/panic         → PanicPage (S09, S10)
/risk          → RiskDashboardPage (S11)
/profile       → ProfilePage

// Subrutas — accesibles desde contexto (no desde bottom nav)
/map/incident/:id          → IncidentDetailSheet (S08)
/map/routes                → RouteComparatorPage (S12)

// Flujo de reporte — FAB flotante desde /map
/report/type               → IncidentTypePage (S05)
/report/form/:type         → DynamicFormPage (S06)
/report/confirm            → ReportConfirmationPage (S07)

// Onboarding — solo primera vez
/                          → SplashPage (S01)
/onboarding                → OnboardingPage (S02)
/login                     → LoginPage (S03)
```

### FAB de reporte
- Botón flotante "+" encima del mapa, esquina inferior derecha
- Color: `#1B3A6B` con ícono `#FFFFFF`
- Ancho: 56px, alto: 56px, border-radius: 16px
- NO vive en el bottom nav — es un FAB independiente
- Tooltip: "Reportar incidente"

---

## PANEL WEB — Sidebar Navigation

### Estructura del Sidebar (240px, fijo a la izquierda)
```
AlertaYa [logo]
─────────────────
● Mapa en Vivo      ← Ítem por defecto al entrar
○ Incidentes
○ Predicciones IA
○ Estadísticas
─────────────────
○ Exportar          ← Separado: es acción, no vista
─────────────────
○ Cerrar sesión     ← Al fondo, color tenue
```

### Reglas de implementación
- Ancho: 240px fijo — nunca colapsable en MVP
- Fondo: `#141720`
- Borde derecho: `0.5px solid #2D3A4A`
- Ítem activo: `border-left: 3px solid #1B3A6B` + `background: #1B3A6B15`
- Ítem hover: `background: #1B3A6B0A`
- Texto activo: `#FFFFFF`
- Texto inactivo: `#6B7A8D`
- "Exportar" separado con `border-top: 0.5px solid #2D3A4A` (es acción)
- "Cerrar sesión" en color `#EF444466` — presente pero no prominente

### Top Bar (60px fijo, encima del contenido)
- Fondo: `#1A1D23`
- Borde inferior: `0.5px solid #2D3A4A`
- Izquierda: breadcrumb de la pantalla actual
- Centro: indicador "En vivo · Actualizado hace Ns" con dot verde pulsante
- Derecha: ícono de campana con badge de alertas + avatar del supervisor

### Rutas (React Router)
```typescript
/auth/login          → LoginPage (W01) — fuera del layout con sidebar
/dashboard           → DashboardPage (W02) — ruta por defecto tras login
/incidents           → IncidentsListPage (W03)
/incidents/:id       → IncidentDetailPage (W04) — drill-down desde lista o mapa
/predictions         → PredictionsPage (W05)
/statistics          → StatisticsPage (W06)
/export              → ExportPage (W07)
```

### AuthGuard
- Todas las rutas excepto `/auth/login` están protegidas por `<AuthGuard>`
- AuthGuard verifica: token Firebase válido + rol "AUTHORITY" en Firestore
- Sin los dos → redirige a `/auth/login`
- Ciudadanos normales NO tienen acceso al panel web — verificar rol

### Pantalla W04 — Drill-down
- No aparece en el sidebar — se accede desde:
  - Clic en un pin del mapa (W02) → abre como página completa con breadcrumb
  - Clic en "Ver detalle" en la tabla (W03) → misma página
- El sidebar permanece visible — solo cambia el contenido principal

---

## FLUJOS DE NAVEGACIÓN CRÍTICOS

### Flujo ciudadano: reporte de incidente
```
MapPage (FAB "+")
  → IncidentTypePage (selección de tipo)
  → DynamicFormPage (formulario dinámico para el tipo seleccionado)
  → ReportConfirmationPage (estado + resultado IA)
  → MapPage (pop to root)
```

### Flujo ciudadano: pánico
```
[Mantener 3s botón pánico en app]
  ↕  [O: 3× volumen físico]
  ↕  [O: palabra clave de voz]
PanicPage (activa Foreground Service)
  → PanicActivePage (grabando — no se puede navegar fuera durante pánico)
  → [PIN correcto desde notificación persistente]
PanicPage (idle de nuevo)
```

### Flujo autoridad: gestión de incidente
```
LoginPage (2FA)
  → DashboardPage (mapa + panel lateral)
    [Clic en pin del mapa]
    → IncidentDetailPage
      → [Asignar unidad]
      → DashboardPage (mapa actualizado)
```
