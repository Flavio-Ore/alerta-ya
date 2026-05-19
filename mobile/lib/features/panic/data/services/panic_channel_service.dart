import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Comunica Flutter con PanicForegroundService via MethodChannel
@lazySingleton
class PanicChannelService {
  static const _channel = MethodChannel('com.example.alertaya/panic');

  /// Inicia el Foreground Service con el tiempo transcurrido actual
  Future<void> startService(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('startPanic', {
        'elapsedSeconds': elapsedSeconds,
      });
    } on PlatformException catch (e) {
      // No es crítico si falla — la grabación sigue en Flutter
      // ignore: avoid_print
      print('PanicChannelService.startService error: ${e.message}');
    }
  }

  /// Detiene el Foreground Service
  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopPanic');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('PanicChannelService.stopService error: ${e.message}');
    }
  }

  /// Actualiza el timer en la notificación persistente
  Future<void> updateElapsed(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('updateElapsed', {
        'elapsedSeconds': elapsedSeconds,
      });
    } on PlatformException {
      // Silenciar — actualizaciones frecuentes pueden fallar sin problema
    }
  }
}
