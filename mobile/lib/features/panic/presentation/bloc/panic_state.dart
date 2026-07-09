part of 'panic_bloc.dart';

abstract class PanicState {
  const PanicState();
}

enum PanicMode {
  silent,
  noise;

  bool get recordAudio => true;
  bool get alarmSound => this == PanicMode.noise;

  static PanicMode fromStorage(String? value) => switch (value) {
        'silent' => PanicMode.silent,
        'noise' => PanicMode.noise,
        _ => PanicMode.noise,
      };
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
    this.trustedContactName,
    this.mode = PanicMode.noise,
  });

  final PanicSessionEntity session;
  final int failedPinAttempts;
  final double amplitude;
  final String? trustedContactName;
  // Snapshot de la elección del usuario al activar — no se actualiza durante la sesión.
  final PanicMode mode;

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
        trustedContactName: trustedContactName,
        mode: mode,
      );
}

class PanicDeactivating extends PanicState {
  const PanicDeactivating();
}

class PanicError extends PanicState {
  const PanicError(this.message);
  final String message;
}
