import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/tutorial/domain/repositories/tutorial_repository.dart';

@injectable
class IsTutorialSeenUseCase {
  const IsTutorialSeenUseCase(this._repository);

  final TutorialRepository _repository;

  Future<Either<Failure, bool>> call() => _repository.isTutorialSeen();
}
