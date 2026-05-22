import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/report/data/schemas/report_form_schemas.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';
import 'package:alertaya/features/report/domain/repositories/report_repository.dart';

/// Repositorio mock para tests y desarrollo manual.
///
/// NO está registrado en DI — el default es `ReportRepositoryImpl` (API real).
/// Para usarlo en tests, regístralo manualmente:
///
/// ```dart
/// getIt.registerLazySingleton<ReportRepository>(() => MockReportRepository());
/// ```
class MockReportRepository implements ReportRepository {
  @override
  DynamicFormSchema getFormSchema(IncidentType type) =>
      ReportFormSchemas.schemaFor(type);

  @override
  Future<Either<Failure, ReportSubmitResult>> createReport(
    ReportEntity report,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const Right(ReportSubmitResult(isPublished: false));
  }
}
