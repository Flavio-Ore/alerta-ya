# PLAN.md — Hoja de ruta del módulo Mobile (Flutter)

> Owner: **Jorge** (Lead Mobile) · Co-owner pánico/mapas: **Anthony**
> Fuente: `docs/TEAM.md`, `docs/architecture/STRUCTURE.md`, `docs/design/SCREENS.md`, `docs/design/NAVIGATION.md`, `docs/architecture/CONSTRAINTS.md`
> Última actualización: 2026-05-07

---

## 1. Diagnóstico actual del módulo `mobile/`

### Lo que YA está hecho
- `pubspec.yaml` existe (verificar contenido contra `STACK.md`)
- `main.dart` inicializa Firebase + DI
- `app.dart` con `MaterialApp.router` y theme con `AppColors.primary` y `DMSans`
- DI con `get_it + injectable` (espera `injection.config.dart` generado por build_runner)
- `app_router.dart` con las 13 rutas mapeadas como **placeholders**
- `core/constants/` (colors, text_styles, app_constants)
- `core/widgets/` (alertaya_button, card, bottom_nav, severity_chip, severity_pin)
- `core/errors/` (failures + exceptions)
- 13 maquetas HTML en `mobile/alertaya_screen/` como referencia visual

### Lo que NO está y se va a necesitar
- Ningún BLoC, use case, repository, datasource o model implementado
- `core/network/` no existe (sin `dio_client`, sin interceptor de Firebase token)
- `core/utils/` no existe (sin Either/Result type, sin AES-256, sin location helpers)
- **Bug arquitectónico en el router**: usa `GoRoute` planos para las tabs (`/map`, `/alerts`, `/panic`, `/risk`, `/profile`). El bottom nav se reconstruye en cada navegación y pierde el estado del tab anterior. Hay que migrar a `StatefulShellRoute.indexedStack`.
- Sin auth guard en el router — cualquiera entra a `/map` sin estar logueado
- `SplashRedirectPage` es un `Scaffold()` vacío sin lógica de redirección
- Onboarding sin persistencia de "primera vez" (Hive)

---

## 2. Riesgo a evitar

Tener las 13 maquetas HTML es trampa mental. Tienta a abrir `splash_screen/code.html`, replicarlo, pasar a la siguiente, y así con las 13. Después, cuando llegue Sprint 2 y sea momento de hacer `POST /reports` con manejo de errores tipado, autenticación con Firebase token y mocking para no depender de Elena, tocaría 4 días de refactor en TODAS las screens para meter `dio_client` y el patrón de errores.

Las screens HTML son **referencia visual**. Se implementan cuando corresponde la fase. Primero los cimientos. Una sola vez. Bien.

---

## 3. Plan en fases — alineado al cronograma del equipo

### FASE 0 — Cimientos (3-4 días, ANTES de cualquier screen real)

| # | Tarea | Por qué |
|---|-------|---------|
| 0.1 | Verificar `pubspec.yaml` contra `STACK.md` y correr `flutter pub get` + `dart run build_runner build --delete-conflicting-outputs` | Sin esto el `injection.config.dart` no existe y el DI explota |
| 0.2 | Crear `core/network/dio_client.dart` con interceptor que adjunta `Authorization: Bearer <Firebase ID token>` en cada request | Todas las features lo van a usar — definirlo UNA vez |
| 0.3 | Crear `core/network/network_info.dart` (connectivity_plus) | Para mostrar UI de "sin conexión" |
| 0.4 | Adoptar `dartz` (`Either<Failure, T>`) para retornar resultados tipados desde repos/use cases | Convención del proyecto según `STRUCTURE.md` |
| 0.5 | Refactorizar `app_router.dart` a `StatefulShellRoute.indexedStack` con las 5 tabs | Sin esto, el bottom nav rompe el estado de los tabs en cada navegación |
| 0.6 | Agregar `redirect:` global de auth guard que consulta el `AuthBloc` (registrado en getIt) | Sin esto el guard no existe |
| 0.7 | Crear `core/utils/either.dart` (helper) y `core/utils/encryption_util.dart` (stub para AES-256, se completa en FASE 4) | Estructuralmente listo |

---

### FASE 1 — Auth (Sprint 1, semanas 1-2 — primera entrega oficial)

S01 Splash → S02 Onboarding → S03 Login. Esta feature se vuelve la **plantilla** que el resto del equipo copia para todo lo demás. Hacerla impecable.

| # | Tarea |
|---|-------|
| 1.1 | `auth/domain/`: `UserEntity` (freezed), `AuthRepository` (interfaz), use cases: `SignInUseCase`, `SignOutUseCase`, `GetCurrentUserUseCase`, `IsFirstLaunchUseCase` |
| 1.2 | `auth/data/`: `UserModel` con `json_serializable`, `FirebaseAuthDataSource`, `OnboardingLocalDataSource` (Hive), `AuthRepositoryImpl` |
| 1.3 | `auth/presentation/bloc/`: `AuthBloc` con `Authenticated`, `Unauthenticated`, `Loading`, `Error` |
| 1.4 | S01 `SplashPage` real: verifica si onboarding está completo + si hay sesión Firebase → redirige a `/onboarding`, `/login` o `/map` |
| 1.5 | S02 `OnboardingPage`: 3 slides con `PageView`, persiste flag `onboarding_completed` con Hive |
| 1.6 | S03 `LoginPage` con `flutter_bloc` + validación |
| 1.7 | Tests con `mocktail` + `bloc_test` para los use cases — establecer el patrón |
| 1.8 | Conectar el `redirect` global del router al estado del `AuthBloc` |

---

### FASE 2 — Flujo de reporte (Sprint 2, semanas 3-4)

S05 → S06 → S07. El flujo más crítico del rol ciudadano.

| # | Tarea |
|---|-------|
| 2.1 | `report/domain/`: `ReportEntity`, `DynamicFormEntity`, use cases `GetFormQuestionsUseCase` + `CreateReportUseCase` |
| 2.2 | `report/data/`: modelos matching `DATA_MODELS.md` § "Formulario dinámico". Solo ROBBERY y ACCIDENT en MVP (R07 de CONSTRAINTS) |
| 2.3 | `ReportBloc` para el flujo multi-paso (tipo → form → submit) |
| 2.4 | S05 `IncidentTypePage`: ROBBERY y ACCIDENT habilitados; los otros 3 dim/lock con badge "Próximamente" |
| 2.5 | S06 `DynamicFormPage`: renderiza preguntas desde el JSON Schema, **siempre incluye "No sé"**, máximo 4 preguntas, solo radio buttons |
| 2.6 | S07 `ReportConfirmationPage`: estado de IA + threshold, mensaje claro "tu reporte se publicará cuando otro ciudadano lo confirme" |
| 2.7 | Mock del backend: registrar `MockReportRepository` por `Environment.dev` en injectable. Si Elena no tiene `POST /reports`, no se bloquea el avance |
| 2.8 | FAB en `MapPage` (S04) que dispara `/report/type` |

---

### FASE 3 — WebSocket + Profile (Sprint 3, semanas 5-6)

| # | Tarea |
|---|-------|
| 3.1 | `core/realtime/socket_client.dart` con `socket_io_client` + reconexión + token |
| 3.2 | Feature `incidents/` compartida con Anthony — domain/data común |
| 3.3 | S08 `IncidentDetailSheet` con confirmaciones Waze-style (`still_here` / `gone`) |
| 3.4 | S13 `ProfilePage`: toggle notificaciones, idioma, cerrar sesión |
| 3.5 | Coordinar con Anthony: cuando se publica un reporte, su mapa recibe el evento `incident:new` |

---

### FASE 4 — Pánico (Sprint 4, semanas 7-8 — junto con Anthony)

División clara para no pisarse:
- **Jorge**: BLoC, use cases, AES-256, upload a GCS via Firebase Storage, lógica de PIN
- **Anthony**: Foreground Service Android, audio recorder, location stream, push notifications

| # | Tarea |
|---|-------|
| 4.1 | `panic/domain/`: `PanicSessionEntity`, `ActivatePanicUseCase`, `DeactivatePanicUseCase` |
| 4.2 | Completar `core/utils/encryption_util.dart` con AES-256 real (paquete `crypto`) |
| 4.3 | `PanicBloc`: estados idle, activating, active, deactivating, error |
| 4.4 | S09/S10: misma ruta `/panic`, UI según estado del BLoC |
| 4.5 | PIN de 4 dígitos para desactivar; 3 fallos → mantener alarma + notificar contacto |

---

### FASE 5 — Risk overlay + rutas (Sprint 5, semanas 9-10)

| # | Tarea |
|---|-------|
| 5.1 | S11 `RiskDashboardPage` consume `GET /risk-zones` |
| 5.2 | S12 `RouteComparatorPage` con OpenRouteService API |
| 5.3 | Risk overlay sobre el mapa de Anthony (heatmap layer) |

---

### FASES 6-8 — Tests, QA, build APK (Sprints 6-8)
Según cronograma del equipo en `docs/TEAM.md`.

---

## 4. Recomendación accionable inmediata

**Para mañana tiene que estar corriendo la FASE 0.** Sin eso, cualquier minuto invertido en una screen es deuda técnica que se paga en la semana 4.

Primer dominó: leer el `pubspec.yaml` actual y compararlo contra `docs/architecture/STACK.md` para preparar la lista de dependencias faltantes.
