import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

@injectable
class CreateReportUseCase {
  const CreateReportUseCase(this._repository);
  final ReportRepository _repository;

  Future<Either<Failure, String>> call(ReportEntity report) =>
      _repository.createReport(report);
}
