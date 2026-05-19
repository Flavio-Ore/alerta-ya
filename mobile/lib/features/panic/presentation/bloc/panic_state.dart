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
    this.amplitude = 0.0,
  });

  final PanicSessionEntity session;
  final int failedPinAttempts;
  // Nivel de amplitud del micrófono — 0.0 (silencio) a 1.0 (máximo)
  // Se actualiza cada 100ms desde AudioRecordingService
  final double amplitude;

  bool get isPinLocked => failedPinAttempts >= AppConstants.panicPinMaxAttempts;

  PanicActive copyWith({
    PanicSessionEntity? session,
    int? failedPinAttempts,
    double? amplitude,
  }) =>
      PanicActive(
        session: session ?? this.session,
        failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
        amplitude: amplitude ?? this.amplitude,
      );
}

class PanicDeactivating extends PanicState {
  const PanicDeactivating();
}

class PanicError extends PanicState {
  const PanicError(this.message);
  final String message;
}
