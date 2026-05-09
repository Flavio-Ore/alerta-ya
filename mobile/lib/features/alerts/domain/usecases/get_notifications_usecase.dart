import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsParams {
  const GetNotificationsParams({
    this.unreadOnly = false,
    this.page = 1,
    this.pageSize = 20,
  });
  final bool unreadOnly;
  final int page;
  final int pageSize;
}

@injectable
class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, List<NotificationEntity>>> call(
          GetNotificationsParams params) =>
      _repository.getNotifications(
        unreadOnly: params.unreadOnly,
        page: params.page,
        pageSize: params.pageSize,
      );
}
