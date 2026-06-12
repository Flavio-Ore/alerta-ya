import 'package:injectable/injectable.dart';

import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/repositories/report_repository.dart';

@injectable
class GetFormSchemaUseCase {
  const GetFormSchemaUseCase(this._repository);
  final ReportRepository _repository;

  DynamicFormSchema call(IncidentType type) => _repository.getFormSchema(type);
}
