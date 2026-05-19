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
    required this.pin,
  });
  final double lat;
  final double lng;
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
