import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/core/network/network_info.dart';
import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';
import 'package:alertaya/features/alerts/domain/repositories/notification_repository.dart';
import 'package:alertaya/features/alerts/data/datasources/notification_remote_datasource.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote, this._networkInfo);
  final NotificationRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      return Right(await _remote.getNotifications(
        unreadOnly: unreadOnly,
        page: page,
        pageSize: pageSize,
      ));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead({
    List<String> ids = const [],
    bool all = false,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(Failure.network());
    try {
      await _remote.markRead(ids: ids, all: all);
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
