import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';
import 'package:alertaya/features/report/domain/repositories/report_repository.dart';

@injectable
class CreateReportUseCase {
  const CreateReportUseCase(this._repository);
  final ReportRepository _repository;

  Future<Either<Failure, ReportSubmitResult>> call(ReportEntity report) =>
      _repository.createReport(report);
}
