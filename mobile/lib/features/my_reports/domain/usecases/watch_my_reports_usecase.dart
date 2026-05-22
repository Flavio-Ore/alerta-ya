import 'package:injectable/injectable.dart';

import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/domain/repositories/my_reports_repository.dart';

@injectable
class WatchMyReportsUseCase {
  const WatchMyReportsUseCase(this._repository);
  final MyReportsRepository _repository;

  Stream<ReportStatusChangedEvent> call() => _repository.watchStatusChanges();
}
