import 'package:injectable/injectable.dart';

import '../entities/form_question_entity.dart';
import '../entities/incident_type.dart';
import '../repositories/report_repository.dart';

@injectable
class GetFormSchemaUseCase {
  const GetFormSchemaUseCase(this._repository);
  final ReportRepository _repository;

  DynamicFormSchema call(IncidentType type) => _repository.getFormSchema(type);
}
