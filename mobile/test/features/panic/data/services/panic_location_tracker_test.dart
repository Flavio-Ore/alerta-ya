import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/services/panic_location_tracker.dart';

void main() {
  group('PanicLocationTracker', () {
    late PanicLocationTracker tracker;
    late List<({double lat, double lng})> emitted;

    setUp(() {
      tracker = PanicLocationTracker();
      emitted = [];
    });

    tearDown(() => tracker.stop());

    test('emite coordenadas periódicamente mientras está activo', () async {
      tracker.start(
        'session-1',
        intervalSeconds: 1,
        onLocation: (lat, lng) => emitted.add((lat: lat, lng: lng)),
        getPosition: () async => (lat: -12.04, lng: -77.03),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      tracker.stop();

      expect(emitted.length, greaterThanOrEqualTo(1));
      expect(emitted.first.lat, -12.04);
      expect(emitted.first.lng, -77.03);
    });

    test('deja de emitir después de stop()', () async {
      tracker.start(
        'session-2',
        intervalSeconds: 1,
        onLocation: (lat, lng) => emitted.add((lat: lat, lng: lng)),
        getPosition: () async => (lat: -11.0, lng: -76.0),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      tracker.stop();
      final countAfterStop = emitted.length;
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(emitted.length, equals(countAfterStop));
    });

    test('falla silenciosamente si getPosition lanza excepción', () async {
      tracker.start(
        'session-3',
        intervalSeconds: 1,
        onLocation: (lat, lng) => emitted.add((lat: lat, lng: lng)),
        getPosition: () async => throw Exception('GPS no disponible'),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      tracker.stop();

      // No lanzó excepción, no emitió nada
      expect(emitted, isEmpty);
    });

    test('start() cancela el timer anterior si ya estaba corriendo', () async {
      tracker.start(
        'session-old',
        intervalSeconds: 1,
        onLocation: (_, __) {},
        getPosition: () async => (lat: 0.0, lng: 0.0),
      );

      // Segundo start() sin stop() previo — no debe duplicar emisiones
      tracker.start(
        'session-new',
        intervalSeconds: 1,
        onLocation: (lat, lng) => emitted.add((lat: lat, lng: lng)),
        getPosition: () async => (lat: -12.0, lng: -77.0),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      tracker.stop();

      // Solo debe haber emisiones del segundo start (session-new)
      expect(emitted.every((p) => p.lat == -12.0), isTrue);
    });
  });
}
