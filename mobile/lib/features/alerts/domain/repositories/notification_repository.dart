import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Unit>> markRead({
    List<String> ids = const [],
    bool all = false,
  });
}
