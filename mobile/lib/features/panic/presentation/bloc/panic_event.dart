part of 'panic_bloc.dart';

abstract class PanicEvent {
  const PanicEvent();
}

class PanicInitialized extends PanicEvent {
  const PanicInitialized();
}

class PanicActivationRequested extends PanicEvent {
  const PanicActivationRequested({
    required this.lat,
    required this.lng,
    this.pin, // null = usar el PIN guardado previamente
    this.recordAudio = true,
    this.alarmSound = true,
  });
  final double lat;
  final double lng;
  final String? pin;
  // Toggles del usuario. Defaults true por seguridad — si no hay prefs cargadas, asumimos lo más protector.
  final bool recordAudio;
  final bool alarmSound;
}

class PanicSavedPinUpdated extends PanicEvent {
  const PanicSavedPinUpdated(this.pin);
  final String pin;
}

class PanicDeactivationRequested extends PanicEvent {
  const PanicDeactivationRequested(this.pin);
  final String pin;
}

// ── Eventos internos — solo el BLoC los dispara ──────────────────────────────

class _PanicAmplitudeUpdated extends PanicEvent {
  const _PanicAmplitudeUpdated(this.amplitude);
  final double amplitude;
}

class _PanicBlockCompleted extends PanicEvent {
  const _PanicBlockCompleted(this.filePath);
  final String filePath;
}

class _PanicLocationTick extends PanicEvent {
  const _PanicLocationTick(this.lat, this.lng);
  final double lat;
  final double lng;
}
