import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

typedef PositionGetter = Future<({double lat, double lng})> Function();

@lazySingleton
class PanicLocationTracker {
  Timer? _timer;

  /// Inicia el rastreo GPS periódico.
  ///
  /// [intervalSeconds] es 30 en producción e inyectable para tests.
  /// [getPosition] es inyectable para tests — por defecto usa Geolocator.
  void start(
    String sessionId, {
    int intervalSeconds = 30,
    required void Function(double lat, double lng) onLocation,
    PositionGetter? getPosition,
  }) {
    stop(); // Cancelar cualquier timer previo

    final posGetter = getPosition ?? _defaultGetPosition;

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      try {
        final pos = await posGetter();
        onLocation(pos.lat, pos.lng);
        debugPrint('[LocationTracker] GPS → ${pos.lat}, ${pos.lng}');
      } catch (e) {
        debugPrint('[LocationTracker] GPS error (descartado): $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('[LocationTracker] Rastreo GPS detenido');
  }

  Future<({double lat, double lng})> _defaultGetPosition() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }
}
