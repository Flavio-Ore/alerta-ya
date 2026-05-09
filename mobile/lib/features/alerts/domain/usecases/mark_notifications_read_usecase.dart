import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkReadParams {
  const MarkReadParams({this.ids = const [], this.all = false});
  final List<String> ids;
  final bool all;
}

@injectable
class MarkNotificationsReadUseCase {
  const MarkNotificationsReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, Unit>> call(MarkReadParams params) =>
      _repository.markRead(ids: params.ids, all: params.all);
}
