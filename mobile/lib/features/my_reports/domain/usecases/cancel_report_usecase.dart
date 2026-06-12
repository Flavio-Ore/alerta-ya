import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/my_reports/domain/repositories/my_reports_repository.dart';

@injectable
class CancelReportUseCase {
  const CancelReportUseCase(this._repository);
  final MyReportsRepository _repository;

  Future<Either<Failure, Unit>> call(String reportId) =>
      _repository.cancelReport(reportId);
}
