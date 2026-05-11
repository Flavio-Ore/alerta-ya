import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/auth/domain/entities/user_entity.dart';
import 'package:alertaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:alertaya/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/is_first_launch_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:alertaya/features/auth/domain/usecases/sign_out_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithEmail,
    this._signOut,
    this._isFirstLaunch,
    this._completeOnboarding,
    this._repository,
  ) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
  }

  final SignInWithEmailUseCase _signInWithEmail;
  final SignOutUseCase _signOut;
  final IsFirstLaunchUseCase _isFirstLaunch;
  final CompleteOnboardingUseCase _completeOnboarding;
  final AuthRepository _repository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final firstResult = await _isFirstLaunch();
    final isFirst = firstResult.fold((_) => false, (v) => v);

    // Firebase emite el estado actual inmediatamente al suscribirse
    final user = await _repository.authStateChanges.first;

    if (user != null) {
      emit(AuthAuthenticated(user));
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
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
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
