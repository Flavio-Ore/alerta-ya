import 'package:dartz/dartz.dart' show Either, Left, Right, Unit, unit;
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/core/network/network_info.dart';
import 'package:alertaya/core/realtime/socket_client.dart';
import 'package:alertaya/features/my_reports/data/datasources/my_reports_remote_datasource.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/domain/repositories/my_reports_repository.dart';

@LazySingleton(as: MyReportsRepository)
class MyReportsRepositoryImpl implements MyReportsRepository {
  const MyReportsRepositoryImpl(this._remote, this._networkInfo, this._socket);
  final MyReportsRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SocketClient _socket;

  @override
  Future<Either<Failure, MyReportsPage>> getMyReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      return Right(await _remote.getMine(page: page, pageSize: pageSize));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Stream<ReportStatusChangedEvent> watchStatusChanges() =>
      _socket.onReportStatusChanged;

  @override
  Future<Either<Failure, Unit>> cancelReport(String reportId) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      await _remote.cancelReport(reportId);
      return const Right(unit);
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
