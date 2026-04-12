# STRUCTURE.md — Estructura de Carpetas AlertaYa

> Clean Architecture aplicada a todos los servicios.
> La dirección de dependencias es siempre hacia adentro:
> Presentation → Application → Domain ← Infrastructure

---

## RAÍZ DEL MONOREPO

```
/
├── CLAUDE.md                        ← Guía principal para Claude Code
├── docker-compose.yml               ← Dev local: todos los servicios
├── .github/
│   └── workflows/
│       ├── ci-api.yml
│       ├── ci-mobile.yml
│       └── ci-ml.yml
├── docs/                            ← DOCUMENTOS DE REFERENCIA
│   ├── architecture/
│   │   ├── STACK.md
│   │   ├── STRUCTURE.md             ← Este archivo
│   │   ├── DATA_MODELS.md
│   │   └── CONSTRAINTS.md
│   ├── design/
│   │   ├── BRAND.md
│   │   ├── NAVIGATION.md
│   │   └── SCREENS.md
│   └── rules/
│       ├── CODING_STANDARDS.md
│       ├── UI_RULES.md
│       └── SECURITY_RULES.md
├── mobile/                          ← App Flutter (ciudadano)
├── web/                             ← Panel React (autoridades)
├── api/                             ← Backend Node.js
└── ml/                              ← Microservicio Python ML
```

---

## APP MÓVIL — `mobile/`

```
mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
├── android/
│   └── app/
│       └── src/main/AndroidManifest.xml   ← Foreground service permissions
├── ios/
├── lib/
│   ├── main.dart                          ← Entry point mínimo
│   ├── app/
│   │   ├── app.dart                       ← MaterialApp + router config
│   │   ├── di/
│   │   │   └── injection.dart             ← get_it + injectable setup
│   │   └── router/
│   │       └── app_router.dart            ← go_router routes
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart            ← TODOS los colores como const
│   │   │   ├── app_text_styles.dart       ← Estilos de texto centralizados
│   │   │   └── app_constants.dart         ← URLs, timeouts, radios, etc.
│   │   ├── errors/
│   │   │   ├── failures.dart              ← Failure sealed classes
│   │   │   └── exceptions.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── network_info.dart
│   │   ├── utils/
│   │   │   ├── either.dart                ← Result type (o usar dartz)
│   │   │   ├── encryption_util.dart       ← AES-256 helpers
│   │   │   └── location_util.dart
│   │   └── widgets/
│   │       ├── alertaya_button.dart       ← Botón primario con brand
│   │       ├── alertaya_chip.dart         ← Severity chips
│   │       ├── alertaya_bottom_nav.dart   ← Bottom nav con pánico central
│   │       └── severity_pin.dart          ← Pin del mapa por severidad
│   │
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   ├── entities/user_entity.dart
│       │   │   ├── repositories/auth_repository.dart      ← Interfaz
│       │   │   └── usecases/
│       │   │       ├── sign_in_usecase.dart
│       │   │       └── sign_out_usecase.dart
│       │   ├── data/
│       │   │   ├── models/user_model.dart
│       │   │   ├── datasources/
│       │   │   │   └── firebase_auth_datasource.dart
│       │   │   └── repositories/auth_repository_impl.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── auth_bloc.dart
│       │       │   ├── auth_event.dart
│       │       │   └── auth_state.dart
│       │       └── pages/
│       │           ├── login_page.dart                    ← S03
│       │           └── onboarding_page.dart               ← S01, S02
│       │
│       ├── map/                                           ← S04 Mapa principal
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── incident_entity.dart
│       │   │   │   └── incident_pin_entity.dart
│       │   │   ├── repositories/incident_repository.dart
│       │   │   └── usecases/
│       │   │       ├── get_active_incidents_usecase.dart
│       │   │       └── confirm_incident_usecase.dart      ← Waze-style
│       │   ├── data/ ...
│       │   └── presentation/
│       │       ├── bloc/ ...
│       │       └── pages/
│       │           ├── map_page.dart
│       │           └── incident_detail_sheet.dart         ← S08
│       │
│       ├── report/                                        ← S05, S06, S07
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── report_entity.dart
│       │   │   │   └── dynamic_form_entity.dart           ← Formulario dinámico
│       │   │   ├── repositories/report_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_report_usecase.dart
│       │   │       └── get_form_questions_usecase.dart
│       │   ├── data/ ...
│       │   └── presentation/
│       │       ├── bloc/ ...
│       │       └── pages/
│       │           ├── incident_type_page.dart            ← S05
│       │           ├── dynamic_form_page.dart             ← S06
│       │           └── report_confirmation_page.dart      ← S07
│       │
│       ├── panic/                                         ← S09, S10
│       │   ├── domain/
│       │   │   ├── entities/panic_session_entity.dart
│       │   │   └── usecases/
│       │   │       ├── activate_panic_usecase.dart
│       │   │       └── deactivate_panic_usecase.dart
│       │   ├── data/
│       │   │   └── services/
│       │   │       ├── panic_foreground_service.dart      ← Android FG Service
│       │   │       ├── audio_recorder_service.dart
│       │   │       └── panic_location_service.dart
│       │   └── presentation/ ...
│       │
│       ├── risk/                                          ← S11 Dashboard riesgo
│       │   └── ...
│       │
│       ├── routes/                                        ← S12 Comparador rutas
│       │   └── ...
│       │
│       ├── alerts/                                        ← Tab Alertas
│       │   └── ...
│       │
│       └── profile/                                       ← S13 Configuración
│           └── ...
│
└── test/
    ├── unit/
    │   └── features/
    │       ├── auth/
    │       ├── report/
    │       └── panic/
    └── widget/
```

---

## PANEL WEB — `web/`

```
web/
├── package.json
├── vite.config.ts
├── tailwind.config.ts              ← Tokens de marca de BRAND.md
├── tsconfig.json
├── .env.example
├── index.html
└── src/
    ├── main.tsx
    ├── App.tsx                     ← Router + Providers
    │
    ├── core/
    │   ├── constants/
    │   │   ├── colors.ts           ← Brand tokens como constantes TS
    │   │   └── api.ts              ← Base URLs
    │   ├── hooks/
    │   │   ├── useAuth.ts
    │   │   └── useRealtime.ts      ← WebSocket hook
    │   ├── lib/
    │   │   ├── axios.ts            ← Instancia con interceptors
    │   │   └── queryClient.ts      ← React Query config
    │   └── components/
    │       ├── ui/
    │       │   ├── Badge.tsx       ← Severity badge (leve/moderado/crítico)
    │       │   ├── Button.tsx
    │       │   ├── Card.tsx
    │       │   └── SeverityDot.tsx
    │       └── layout/
    │           ├── Sidebar.tsx     ← Nav principal W02–W07
    │           ├── TopBar.tsx
    │           └── AuthGuard.tsx   ← Protección de rutas
    │
    └── features/
        ├── auth/
        │   ├── components/
        │   │   └── TwoFactorInput.tsx   ← OTP 6 dígitos
        │   ├── hooks/useLogin.ts
        │   └── pages/LoginPage.tsx      ← W01
        │
        ├── dashboard/
        │   ├── components/
        │   │   ├── LiveMap.tsx          ← Leaflet mapa de calor
        │   │   ├── StatCards.tsx        ← 4 KPIs superiores
        │   │   └── IncidentSidePanel.tsx ← Panel derecho deslizable
        │   └── pages/DashboardPage.tsx  ← W02
        │
        ├── incidents/
        │   ├── components/
        │   │   ├── IncidentTable.tsx
        │   │   ├── IncidentFilters.tsx
        │   │   ├── DynamicFormData.tsx  ← Respuestas formulario (sin identidad)
        │   │   ├── IncidentTimeline.tsx ← Escalada automática
        │   │   └── UnitAssignment.tsx   ← Asignar unidad operativa
        │   ├── hooks/
        │   │   ├── useIncidents.ts
        │   │   └── useAssignUnit.ts
        │   └── pages/
        │       ├── IncidentsListPage.tsx   ← W03
        │       └── IncidentDetailPage.tsx  ← W04
        │
        ├── predictions/
        │   ├── components/
        │   │   ├── PredictiveMap.tsx
        │   │   ├── RiskZoneList.tsx
        │   │   └── BehaviorPatterns.tsx    ← Insights de formulario
        │   └── pages/PredictionsPage.tsx   ← W05
        │
        ├── statistics/
        │   ├── components/
        │   │   ├── IncidentTypeChart.tsx
        │   │   ├── HourDayHeatmap.tsx
        │   │   └── FormDataInsights.tsx    ← Análisis formulario dinámico
        │   └── pages/StatisticsPage.tsx    ← W06
        │
        └── export/
            ├── components/
            │   ├── ExportConfig.tsx
            │   └── ReportPreview.tsx
            └── pages/ExportPage.tsx        ← W07
```

---

## BACKEND API — `api/`

```
api/
├── package.json
├── tsconfig.json
├── .env.example
├── Dockerfile
├── prisma/
│   ├── schema.prisma           ← Esquemas según DATA_MODELS.md
│   └── migrations/
│
└── src/
    ├── index.ts                ← Entry point: express app + socket.io
    │
    ├── core/
    │   ├── config/
    │   │   ├── env.ts          ← Variables de entorno validadas con zod
    │   │   ├── firebase.ts     ← Firebase Admin init
    │   │   └── redis.ts        ← Redis client
    │   ├── middleware/
    │   │   ├── auth.middleware.ts       ← Verificar Firebase token
    │   │   ├── rateLimiter.middleware.ts ← 3 reportes/hora por cuenta
    │   │   ├── errorHandler.middleware.ts
    │   │   └── logger.middleware.ts
    │   └── errors/
    │       └── AppError.ts
    │
    ├── features/
    │   ├── incidents/
    │   │   ├── domain/
    │   │   │   ├── Incident.ts               ← Entidad con lógica de threshold
    │   │   │   └── IncidentRepository.ts     ← Interfaz
    │   │   ├── application/
    │   │   │   ├── CreateReportUseCase.ts
    │   │   │   ├── GetActiveIncidentsUseCase.ts
    │   │   │   ├── ConfirmIncidentUseCase.ts  ← Waze-style
    │   │   │   └── ThresholdEngine.ts         ← Lógica de publicación
    │   │   ├── infrastructure/
    │   │   │   ├── PrismaIncidentRepository.ts
    │   │   │   └── RedisThresholdStore.ts
    │   │   └── presentation/
    │   │       ├── incidents.router.ts
    │   │       ├── incidents.controller.ts
    │   │       └── incidents.schema.ts       ← Zod schemas
    │   │
    │   ├── panic/
    │   │   ├── application/
    │   │   │   └── PanicSessionUseCase.ts
    │   │   └── presentation/ ...
    │   │
    │   ├── notifications/
    │   │   ├── application/
    │   │   │   └── SendPushUseCase.ts        ← FCM via Firebase Admin
    │   │   └── infrastructure/
    │   │       └── FCMNotificationService.ts
    │   │
    │   ├── geofencing/
    │   │   └── application/
    │   │       └── GeofenceCheckUseCase.ts   ← PostGIS ST_DWithin
    │   │
    │   └── auth/
    │       └── presentation/
    │           └── auth.router.ts
    │
    └── sockets/
        └── incidentSocket.ts              ← WebSocket: mapa en vivo
```

---

## MICROSERVICIO ML — `ml/`

```
ml/
├── requirements.txt
├── Dockerfile
├── .env.example
├── pytest.ini
│
└── src/
    ├── main.py                  ← FastAPI app
    ├── core/
    │   ├── config.py            ← Pydantic Settings
    │   └── database.py          ← SQLAlchemy engine
    │
    ├── features/
    │   ├── verification/
    │   │   ├── domain/
    │   │   │   └── report_verifier.py    ← Isolation Forest
    │   │   ├── infrastructure/
    │   │   │   └── model_loader.py
    │   │   └── presentation/
    │   │       └── router.py
    │   │
    │   └── prediction/
    │       ├── domain/
    │       │   └── risk_predictor.py     ← Random Forest + Prophet
    │       ├── infrastructure/
    │       │   └── model_store.py        ← joblib persistence
    │       └── presentation/
    │           └── router.py
    │
    ├── models/                   ← Modelos entrenados (.joblib)
    │   ├── verifier_v1.joblib
    │   └── predictor_v1.joblib
    │
    └── tests/
        ├── test_verifier.py
        └── test_predictor.py
```

---

## NOTAS IMPORTANTES

1. **Nunca** poner lógica de negocio en `presentation/` — solo controllers y validators
2. **Nunca** hacer imports circulares entre features — si se necesita compartir, va a `core/`
3. Los modelos de dominio son **inmutables** (freezed en Flutter, readonly en TS)
4. Cada feature tiene sus propios tests en `test/` — misma estructura que `src/`
5. Las interfaces de repositorios viven en `domain/` — las implementaciones en `infrastructure/`
