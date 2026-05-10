import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart';

@injectable
class IsFirstLaunchUseCase {
  const IsFirstLaunchUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, bool>> call() => _repository.isFirstLaunch();
}
