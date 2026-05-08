import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.completeOnboarding();
}
