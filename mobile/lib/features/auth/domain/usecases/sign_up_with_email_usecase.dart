import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailParams {
  const SignUpWithEmailParams({required this.email, required this.password});
  final String email;
  final String password;
}

@injectable
class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(SignUpWithEmailParams params) =>
      _repository.signUpWithEmail(email: params.email, password: params.password);
}
