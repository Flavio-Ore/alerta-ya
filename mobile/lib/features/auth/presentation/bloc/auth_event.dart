part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Dispatched en SplashPage al iniciar la app.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthEmailSignInRequested extends AuthEvent {
  const AuthEmailSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Dispatched cuando el usuario completa el onboarding.
class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}
