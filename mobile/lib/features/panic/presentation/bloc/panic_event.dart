part of 'panic_bloc.dart';

abstract class PanicEvent {
  const PanicEvent();
}

// Chequea secure storage al iniciar la app — recupera sesión activa si existe
class PanicInitialized extends PanicEvent {
  const PanicInitialized();
}

// El usuario presionó el botón de pánico y confirmó el PIN de 4 dígitos
class PanicActivationRequested extends PanicEvent {
  const PanicActivationRequested({
    required this.lat,
    required this.lng,
    required this.pin,
  });
  final double lat;
  final double lng;
  final String pin; // 4 dígitos — se almacena en secure storage
}

// El usuario ingresó su PIN para desactivar
class PanicDeactivationRequested extends PanicEvent {
  const PanicDeactivationRequested(this.pin);
  final String pin;
}
