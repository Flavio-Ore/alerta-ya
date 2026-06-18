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
    this.trustedContactName,
    this.recordAudio = true,
    this.alarmSound = true,
    this.recordVideo = false,
    this.currentVideoClip = 0,
  });

  final PanicSessionEntity session;
  final int failedPinAttempts;
  final double amplitude;
  final String? trustedContactName;
  // Snapshot de la elección del usuario al activar — no se actualiza durante la sesión.
  final bool recordAudio;
  final bool alarmSound;
  final bool recordVideo;
  // Clip de video actual (1-based). 0 = no se está grabando video.
  final int currentVideoClip;

  bool get isPinLocked => failedPinAttempts >= AppConstants.panicPinMaxAttempts;

  PanicActive copyWith({
    PanicSessionEntity? session,
    int? failedPinAttempts,
    double? amplitude,
    int? currentVideoClip,
  }) =>
      PanicActive(
        session: session ?? this.session,
        failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
        amplitude: amplitude ?? this.amplitude,
        trustedContactName: trustedContactName,
        recordAudio: recordAudio,
        alarmSound: alarmSound,
        recordVideo: recordVideo,
        currentVideoClip: currentVideoClip ?? this.currentVideoClip,
      );
}

class PanicDeactivating extends PanicState {
  const PanicDeactivating();
}

class PanicError extends PanicState {
  const PanicError(this.message);
  final String message;
}
