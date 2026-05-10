import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/auth/domain/entities/user_entity.dart';
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:alertaya/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:alertaya/features/auth/data/datasources/onboarding_local_datasource.dart';

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
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _authDataSource.signUpWithEmail(
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
    try {
      final model = await _authDataSource.signInWithGoogle();
      return Right(model.toEntity());
    } on UserCancelledException {
      return const Left(Failure.server(statusCode: 0, message: 'sign_in_cancelled'));
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
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
