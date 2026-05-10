import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/core/network/network_info.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart';
import 'package:alertaya/features/incidents/data/datasources/incident_remote_datasource.dart';

@LazySingleton(as: IncidentRepository)
class IncidentRepositoryImpl implements IncidentRepository {
  const IncidentRepositoryImpl(this._remote, this._networkInfo);
  final IncidentRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<IncidentEntity>>> getIncidents({
    String? severity,
    String? district,
    String? since,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      return Right(await _remote.getIncidents(
        severity: severity,
        district: district,
        since: since,
        page: page,
        pageSize: pageSize,
      ));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on NotFoundException {
      return const Left(Failure.notFound());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncidentDetailEntity>> getIncidentDetail(
      String id) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      return Right(await _remote.getIncidentDetail(id));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on NotFoundException {
      return const Left(Failure.notFound());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmIncident(String id, String vote) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      await _remote.confirmIncident(id, vote);
      return const Right(unit);
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmZone(
      String zoneKey, String response) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      await _remote.confirmZone(zoneKey, response);
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
