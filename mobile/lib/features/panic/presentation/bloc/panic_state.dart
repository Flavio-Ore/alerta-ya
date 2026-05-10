part of 'panic_bloc.dart';

abstract class PanicState {
  const PanicState();
}

class PanicIdle extends PanicState {
  const PanicIdle();
}

class PanicActivating extends PanicState {
  const PanicActivating();
}

class PanicActive extends PanicState {
  const PanicActive({
    required this.session,
    this.failedPinAttempts = 0,
  });
  final PanicSessionEntity session;
  final int failedPinAttempts;

  bool get isPinLocked =>
      failedPinAttempts >= AppConstants.panicPinMaxAttempts;

  PanicActive copyWith({
    PanicSessionEntity? session,
    int? failedPinAttempts,
  }) =>
      PanicActive(
        session: session ?? this.session,
        failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      );
}

class PanicDeactivating extends PanicState {
  const PanicDeactivating();
}

class PanicError extends PanicState {
  const PanicError(this.message);
  final String message;
}
