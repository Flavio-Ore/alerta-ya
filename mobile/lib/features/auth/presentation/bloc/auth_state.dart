part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserEntity user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.isFirstLaunch = false});

  /// true → SplashPage redirige a /onboarding en lugar de /login
  final bool isFirstLaunch;
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
