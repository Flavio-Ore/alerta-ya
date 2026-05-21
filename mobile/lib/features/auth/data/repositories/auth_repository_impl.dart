import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/onboarding_local_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._authDataSource, this._onboardingDataSource);

  final FirebaseAuthDataSource _authDataSource;
  final OnboardingLocalDataSource _onboardingDataSource;

  @override
  Stream<UserEntity?> get authStateChanges =>
      _authDataSource.authStateChanges.map((model) => model?.toEntity());

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _authDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(model.toEntity());
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    // Requiere google_sign_in package + google-services.json — Sprint 2
    return const Left(Failure.unknown(message: 'Google Sign-In disponible próximamente'));
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFirstLaunch() async {
    try {
      return Right(_onboardingDataSource.isFirstLaunch());
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding() async {
    try {
      await _onboardingDataSource.completeOnboarding();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
