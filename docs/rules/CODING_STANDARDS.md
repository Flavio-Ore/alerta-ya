# CODING_STANDARDS.md — Convenciones de Código

---

## IDIOMAS

```
Código (variables, funciones, clases, archivos): INGLÉS
Comentarios explicativos complejos: ESPAÑOL
Strings de UI visibles al usuario: ESPAÑOL
Mensajes de error al usuario: ESPAÑOL
Logs internos del servidor: INGLÉS
Nombres de routes/endpoints: INGLÉS (kebab-case)
```

---

## NOMBRADO

### General
```
Clases:           PascalCase       → IncidentEntity, ThresholdEngine
Interfaces:       PascalCase + I   → IIncidentRepository (TS) | interfaz sin prefijo (Dart)
Funciones/métodos: camelCase       → createReport(), getActiveIncidents()
Variables:        camelCase        → incidentType, formData
Constantes:       SCREAMING_SNAKE  → MAX_REPORTS_PER_HOUR = 3
Archivos TS/JS:   kebab-case       → incident-repository.ts
Archivos Dart:    snake_case       → incident_repository.dart
Archivos React:   PascalCase       → IncidentTable.tsx
```

### Endpoints API
```
GET    /incidents              → listar incidentes activos (público)
POST   /incidents/reports      → crear reporte (autenticado)
POST   /incidents/:id/confirm  → confirmar Waze (autenticado)
GET    /zones/:lat/:lng/risk   → riesgo de zona
POST   /panic/sessions         → activar pánico
DELETE /panic/sessions/:id     → desactivar pánico
GET    /predictions/:district  → predicción IA
```

---

## FLUTTER — Dart

### Estructura de archivos
```dart
// 1. Imports dart/flutter
import 'dart:async';
import 'package:flutter/material.dart';

// 2. Imports de packages externos
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// 3. Imports internos — desde más general a más específico
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
```

### Entidades de dominio (freezed)
```dart
@freezed
class IncidentEntity with _$IncidentEntity {
  const factory IncidentEntity({
    required String id,
    required IncidentType type,
    required Severity severity,
    required double lat,
    required double lng,
    required String district,
    required int confirmCount,
    required DateTime expiresAt,
    FormSummary? formSummary,
  }) = _IncidentEntity;
}
```

### BLoC pattern
```dart
// Events: descripción de intención del usuario — siempre sealed class (Dart 3)
sealed class IncidentEvent {}
class LoadActiveIncidentsEvent extends IncidentEvent {}
class ConfirmIncidentEvent extends IncidentEvent {
  final String incidentId;
  final ConfirmAction action; // stillHere | gone
  const ConfirmIncidentEvent({required this.incidentId, required this.action});
}

// States: descripción del estado de la UI
@freezed
sealed class IncidentState with _$IncidentState {
  const factory IncidentState.initial()                                      = IncidentInitial;
  const factory IncidentState.loading()                                      = IncidentLoading;
  const factory IncidentState.loaded(List<IncidentEntity> incidents)         = IncidentLoaded;
  const factory IncidentState.error(String message)                          = IncidentError;
}
```

### Consumir BLoC en widgets

```dart
// ✅ Preferir context.read / context.watch — más conciso que BlocProvider.of
context.read<IncidentBloc>().add(LoadActiveIncidentsEvent());
context.watch<IncidentBloc>().state;

// ✅ BlocBuilder con buildWhen para evitar rebuilds innecesarios
BlocBuilder<IncidentBloc, IncidentState>(
  buildWhen: (previous, current) => previous != current,
  builder: (context, state) {
    return switch (state) {
      IncidentInitial()              => const SizedBox.shrink(),
      IncidentLoading()              => const CircularProgressIndicator(),
      IncidentLoaded(:final incidents) => IncidentList(incidents: incidents),
      IncidentError(:final message)  => ErrorWidget(message: message),
    };
  },
)

// ✅ BlocListener para side effects (navegación, snackbars) — NUNCA en builder
BlocListener<IncidentBloc, IncidentState>(
  listener: (context, state) {
    if (state case IncidentError(:final message)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  },
  child: ...,
)

// ✅ Patrón freezed — switch nativo Dart 3 (NO usar .when() ni .map(), son legado)
final widget = switch (state) {
  IncidentInitial()                => const SizedBox.shrink(),
  IncidentLoading()                => const CircularProgressIndicator(),
  IncidentLoaded(:final incidents) => IncidentList(incidents: incidents),
  IncidentError(:final message)    => ErrorWidget(message: message),
};
```

### Widgets
```dart
// SIEMPRE const constructors donde sea posible
class AlertaYaButton extends StatelessWidget {
  const AlertaYaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Colores SIEMPRE desde AppColors — nunca hardcodeado
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgLight,
        minimumSize: const Size(double.infinity, 52),
        shape: const StadiumBorder(),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label, style: AppTextStyles.buttonLabel),
    );
  }
}
```

### UseCase pattern
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class CreateReportUseCase implements UseCase<Report, CreateReportParams> {
  final IReportRepository repository;
  CreateReportUseCase(this.repository);

  @override
  Future<Either<Failure, Report>> call(CreateReportParams params) async {
    // Validar rate limiting antes de llamar al repo
    // Nunca lógica de negocio en el BLoC
    return repository.createReport(params);
  }
}
```

---

## TYPESCRIPT / REACT

### Componentes
```tsx
// Siempre FC con props tipadas explícitamente
interface IncidentTableProps {
  incidents: ActiveIncidentResponse[];
  onSelectIncident: (id: string) => void;
  isLoading?: boolean;
}

export const IncidentTable: FC<IncidentTableProps> = ({
  incidents,
  onSelectIncident,
  isLoading = false,
}) => {
  // Colores SIEMPRE desde import, nunca hardcodeados
  return (
    <div className="ay-table-container">
      {incidents.map(incident => (
        <IncidentRow
          key={incident.id}
          incident={incident}
          onSelect={() => onSelectIncident(incident.id)}
        />
      ))}
    </div>
  );
};
```

### Hooks personalizados
```typescript
// Prefijo "use" siempre
export const useActiveIncidents = () => {
  return useQuery({
    queryKey: ['incidents', 'active'],
    queryFn: () => incidentService.getActive(),
    refetchInterval: 2000, // Actualización cada 2s para mapa en vivo
    staleTime: 1000,
  });
};
```

### Zod schemas (validación)
```typescript
// Siempre validar en el borde del sistema, no en la lógica de negocio
export const createReportSchema = z.object({
  type: z.enum(['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS']),
  lat: z.number().min(-12.5).max(-11.5),  // Bounding box Lima
  lng: z.number().min(-77.5).max(-76.5),
  formData: z.record(z.string()),
  mediaUrls: z.array(z.string().url()).optional(),
});
```

---

## NODE.JS — Backend

### Estructura de controller
```typescript
// Controllers son thin — solo orquestan, sin lógica
export class IncidentController {
  constructor(private readonly createReportUseCase: CreateReportUseCase) {}

  createReport = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const dto = createReportSchema.parse(req.body);
      const userId = req.user!.uid; // Viene del auth middleware
      const result = await this.createReportUseCase.execute({ ...dto, userId });
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  };
}
```

### Error handling
```typescript
// Siempre AppError para errores de dominio
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly message: string,
    public readonly isOperational = true,
  ) {
    super(message);
  }
}

// En use cases
if (reportCount >= MAX_REPORTS_PER_HOUR) {
  throw new AppError(429, 'Límite de reportes por hora alcanzado');
}
```

---

## PYTHON — ML Service

```python
# Type hints siempre
from typing import Optional
from pydantic import BaseModel

class VerifyReportRequest(BaseModel):
    incident_type: str
    lat: float
    lng: float
    hour: int
    form_data: dict[str, str]
    report_count: int

class VerifyReportResponse(BaseModel):
    is_coherent: bool
    confidence: float          # 0.0 – 1.0
    suggested_severity: str    # "LOW" | "MODERATE" | "CRITICAL"
    processing_time_ms: float

# Funciones en snake_case
async def verify_report(request: VerifyReportRequest) -> VerifyReportResponse:
    ...
```

---

## TESTING

### Cobertura mínima requerida
```
Lógica de dominio (UseCases, Entities): 90%
Repositorios (con mocks): 80%
Controllers (integration): 70%
Widgets/Componentes UI: 60% (solo flujos críticos)
```

### Nombrado de tests
```
// GIVEN - WHEN - THEN
test('GIVEN reporte sin confirmar WHEN se envía el mismo userId THEN retorna rate limit error')
test('GIVEN 3 reportes con arma de fuego WHEN threshold engine evalúa THEN escala a CRÍTICO')
```

### Mocking
```dart
// Flutter: mocktail
class MockIncidentRepository extends Mock implements IIncidentRepository {}

// Node.js: jest
jest.mock('../infrastructure/PrismaIncidentRepository');
```

---

## GIT

```
Commit format: <tipo>(<scope>): <descripción en español>

Tipos:
  feat:     nueva funcionalidad
  fix:      corrección de bug
  refactor: refactoring sin cambio funcional
  test:     agregar o modificar tests
  docs:     cambios en documentación
  chore:    cambios de configuración, deps

Ejemplos:
  feat(report): agregar formulario dinámico para robo y accidente
  fix(threshold): corregir conteo de confirmaciones Waze
  test(panic): agregar tests para Foreground Service
```
