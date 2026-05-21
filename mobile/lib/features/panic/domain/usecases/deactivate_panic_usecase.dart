import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/panic/domain/repositories/panic_repository.dart';

@injectable
class DeactivatePanicUseCase {
  const DeactivatePanicUseCase(this._repository);
  final PanicRepository _repository;

  Future<Either<Failure, Unit>> call(String sessionId) =>
      _repository.stopSession(sessionId);
}
