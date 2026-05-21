import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Emite el usuario actual al suscribirse y ante cada cambio de sesión.
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, bool>> isFirstLaunch();

  Future<Either<Failure, Unit>> completeOnboarding();

  Future<Either<Failure, Unit>> deleteAccount();
}
