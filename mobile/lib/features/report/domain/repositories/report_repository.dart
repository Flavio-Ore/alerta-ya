import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';

abstract class ReportRepository {
  DynamicFormSchema getFormSchema(IncidentType type);
  Future<Either<Failure, ReportSubmitResult>> createReport(ReportEntity report);
}
