import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/repositories/report_repository.dart';
import 'package:alertaya/features/report/data/schemas/report_form_schemas.dart';

/// Repositorio mock para desarrollo — se reemplaza con la implementación real
/// cuando el backend POST /reports esté disponible.
@LazySingleton(as: ReportRepository)
class MockReportRepository implements ReportRepository {
  @override
  DynamicFormSchema getFormSchema(IncidentType type) =>
      ReportFormSchemas.schemaFor(type);

  @override
  Future<Either<Failure, String>> createReport(ReportEntity report) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const Right('mock-report-id');
  }
}
