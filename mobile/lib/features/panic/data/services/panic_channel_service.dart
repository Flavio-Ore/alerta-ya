import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Comunica Flutter con PanicForegroundService via MethodChannel.
/// También recibe llamadas entrantes desde Android (ej: volumen triple-press).
@lazySingleton
class PanicChannelService {
  static const _channel = MethodChannel('com.example.alertaya/panic');

  final _volumeTrigger = StreamController<void>.broadcast();

  /// Emite cuando Android detecta 3 pulsaciones de volumen en < 2 segundos.
  Stream<void> get volumeTriggerStream => _volumeTrigger.stream;

  PanicChannelService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'triggerVolumePanic') {
        _volumeTrigger.add(null);
      }
    });
  }

  /// Inicia el Foreground Service con el tiempo transcurrido actual.
  /// [alarmSound] controla si el FGS reproduce la sirena audible.
  Future<void> startService(
    int elapsedSeconds, {
    bool alarmSound = true,
  }) async {
    try {
      await _channel.invokeMethod('startPanic', {
        'elapsedSeconds': elapsedSeconds,
        'alarmSound': alarmSound,
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

  void dispose() => _volumeTrigger.close();
}
