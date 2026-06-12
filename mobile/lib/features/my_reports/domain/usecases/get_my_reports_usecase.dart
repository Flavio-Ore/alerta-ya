import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/domain/repositories/my_reports_repository.dart';

class GetMyReportsParams {
  const GetMyReportsParams({this.page = 1, this.pageSize = 20});
  final int page;
  final int pageSize;
}

@injectable
class GetMyReportsUseCase {
  const GetMyReportsUseCase(this._repository);
  final MyReportsRepository _repository;

  Future<Either<Failure, MyReportsPage>> call(GetMyReportsParams params) =>
      _repository.getMyReports(page: params.page, pageSize: params.pageSize);
}
