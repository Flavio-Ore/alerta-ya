import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/fcm_service.dart';
import 'package:alertaya/features/auth/domain/entities/user_entity.dart';
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:alertaya/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/is_first_launch_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/sign_up_with_email_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithEmail,
    this._signUpWithEmail,
    this._signOut,
    this._isFirstLaunch,
    this._completeOnboarding,
    this._repository,
    this._fcm,
  ) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailSignUpRequested>(_onEmailSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
  }

  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignOutUseCase _signOut;
  final IsFirstLaunchUseCase _isFirstLaunch;
  final CompleteOnboardingUseCase _completeOnboarding;
  final AuthRepository _repository;
  final FcmService _fcm;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final firstResult = await _isFirstLaunch();
    final isFirst = firstResult.fold((_) => false, (v) => v);

    final user = await _repository.authStateChanges.first;

    if (user != null) {
      emit(AuthAuthenticated(user));
      unawaited(_fcm.registerToken());
    } else {
      emit(AuthUnauthenticated(isFirstLaunch: isFirst));
    }
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) {
        emit(AuthAuthenticated(user));
        unawaited(_fcm.registerToken());
      },
    );
  }

  Future<void> _onEmailSignUp(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signUpWithEmail(
      SignUpWithEmailParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) {
        emit(AuthAuthenticated(user));
        unawaited(_fcm.registerToken());
      },
    );
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _repository.signInWithGoogle();

    result.fold(
      (failure) {
        if (failure.toString().contains('sign_in_cancelled')) {
          emit(const AuthUnauthenticated(isFirstLaunch: false));
        } else {
          emit(AuthError(failure.toString()));
        }
      },
      (user) {
        emit(AuthAuthenticated(user));
        unawaited(_fcm.registerToken());
      },
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _fcm.unregisterToken();
    await _signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    await _completeOnboarding();
    emit(const AuthUnauthenticated());
  }
}
