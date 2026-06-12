import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/auth/domain/entities/user_entity.dart';
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailParams {
  const SignInWithEmailParams({required this.email, required this.password});
  final String email;
  final String password;
}

@injectable
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) =>
      _repository.signInWithEmail(email: params.email, password: params.password);
}
