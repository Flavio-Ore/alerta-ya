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
    this.mode = PanicMode.noise,
  });
  final double lat;
  final double lng;
  final String? pin;
  // Modo elegido por el usuario. Default protector: alarma sonora + grabación.
  final PanicMode mode;
}

class PanicSavedPinUpdated extends PanicEvent {
  const PanicSavedPinUpdated(this.pin);
  final String pin;
}

class PanicDeactivationRequested extends PanicEvent {
  const PanicDeactivationRequested(this.pin);
  final String pin;
}

// Tras el bloqueo por exceso de intentos, reabre el ingreso de PIN.
// La UI lo dispara solo después del cooldown — no desactiva, solo permite reintentar.
class PanicPinRetryRequested extends PanicEvent {
  const PanicPinRetryRequested();
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

class _PanicVolumeActivated extends PanicEvent {
  const _PanicVolumeActivated();
}
