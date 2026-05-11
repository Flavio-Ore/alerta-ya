import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/form_question_entity.dart';
import '../entities/incident_type.dart';
import '../entities/report_entity.dart';

abstract class ReportRepository {
  DynamicFormSchema getFormSchema(IncidentType type);
  Future<Either<Failure, String>> createReport(ReportEntity report);
}
