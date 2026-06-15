import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/core/network/network_info.dart';
import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';
import 'package:alertaya/features/panic/domain/repositories/panic_repository.dart';
import 'package:alertaya/features/panic/data/datasources/panic_remote_datasource.dart';

@LazySingleton(as: PanicRepository)
class PanicRepositoryImpl implements PanicRepository {
  const PanicRepositoryImpl(this._remote, this._networkInfo);
  final PanicRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, PanicStartResult>> startSession({
    required double lat,
    required double lng,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      return Right(await _remote.startSession(lat: lat, lng: lng));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> stopSession(String sessionId) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      await _remote.stopSession(sessionId);
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
  Future<void> updateLocation({
    required String sessionId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _remote.updateLocation(sessionId: sessionId, lat: lat, lng: lng);
    } catch (e) {
      debugPrint('[PanicRepo] updateLocation falló (descartado): $e');
    }
  }
}
