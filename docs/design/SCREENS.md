# SCREENS.md — Inventario de Pantallas

---

## APP MÓVIL — 13 pantallas

| ID | Nombre | Ruta | Feature | Sprint |
|----|--------|------|---------|--------|
| S01 | Splash Screen | `/` | auth | S1 |
| S02 | Onboarding (3 slides) | `/onboarding` | auth | S1 |
| S03 | Login / Registro | `/login` | auth | S1 |
| S04 | Mapa Principal | `/map` | map | S2 |
| S05 | Selección tipo incidente | `/report/type` | report | S2 |
| S06 | Formulario dinámico | `/report/form/:type` | report | S2 |
| S07 | Confirmación de reporte | `/report/confirm` | report | S2 |
| S08 | Detalle de pin + Waze | `/map/incident/:id` | map | S3 |
| S09 | Pánico — idle | `/panic` | panic | S5 |
| S10 | Pánico — activo | `/panic/active` | panic | S5 |
| S11 | Dashboard de riesgo | `/risk` | risk | S4 |
| S12 | Comparador de rutas | `/map/routes` | routes | S5 |
| S13 | Configuración personal | `/profile` | profile | S3 |

### Tab de Alertas (no listada como pantalla individual)
- Es una lista dentro del tab "Alertas" del bottom nav
- Feature: `alerts/`
- Contiene: historial de pushes recibidas + estado de mis reportes

---

## PANEL WEB AUTORIDADES — 8 pantallas

| ID | Nombre | Ruta | Feature | Sprint |
|----|--------|------|---------|--------|
| W01 | Login + 2FA | `/auth/login` | auth | S4 |
| W02 | Dashboard + Mapa en vivo | `/dashboard` | dashboard | S4 |
| W03 | Lista de incidentes | `/incidents` | incidents | S4 |
| W04 | Detalle de incidente | `/incidents/:id` | incidents | S4 |
| W05 | Predicciones IA | `/predictions` | predictions | S4 |
| W06 | Estadísticas | `/statistics` | statistics | S6 |
| W07 | Exportar reportes | `/export` | export | S6 |

---

## ELEMENTOS TRANSVERSALES (siempre presentes)

### App móvil
```
Bottom Navigation Bar:
  - Siempre visible excepto en: S01, S02, S03, S10 (pánico activo)
  - 5 ítems: Mapa | Alertas | [PÁNICO] | Riesgo | Perfil

FAB de reporte:
  - Visible solo en S04 (mapa principal)
  - Posición: bottom-right, por encima del bottom nav
```

### Panel web
```
Sidebar (240px):
  - Siempre visible en W02–W07
  - Oculto en W01 (login)

Top Bar (60px):
  - Siempre visible en W02–W07
  - Oculto en W01 (login)
```

---

## NOTAS DE IMPLEMENTACIÓN POR PANTALLA

### S06 — Formulario Dinámico
- MVP solo implementa: ROBBERY y ACCIDENT
- La pantalla recibe el tipo como parámetro de ruta
- Carga preguntas desde el backend según el tipo
- Máximo 4 preguntas, solo opciones múltiples
- Siempre incluir "No sé" en preguntas situacionales
- Botón "Enviar" habilitado desde que Q1 tiene respuesta

### S09/S10 — Pánico
- S09 (idle) y S10 (activo) son la misma ruta `/panic`
- El estado cambia según `PanicBloc` state
- Durante S10: bottom nav oculto, navegación bloqueada
- Foreground Service corre independiente de la pantalla visible

### W04 — Detalle de Incidente
- Acceso exclusivo por drill-down (mapa o tabla)
- No aparece en el sidebar
- Los datos del formulario dinámico se muestran de forma AGREGADA
- Nunca mostrar qué usuario específico respondió qué

### W02 — Dashboard
- Es la pantalla por defecto post-login
- El panel derecho de incidentes activos es un componente deslizable
- El mapa usa Leaflet.js con tiles de dark mode
- Actualización del mapa: WebSocket (tiempo real, <2s latencia)
