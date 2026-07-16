import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/risk/domain/entities/risk_info.dart';

void main() {
  group('RiskInfo.fromJson', () {
    test('parsea un snapshot con datos completos', () {
      final json = {
        'district': 'Miraflores',
        'hour': 21,
        'riskScore': 72,
        'level': 'high',
        'topType': 'ROBBERY',
        'topSeverity': 'CRITICAL',
        'confidence': 'high',
        'badHours': [20, 21, 22],
        'safestHours': [4, 5, 6],
        'nearbyTiles': [
          {'lat': -12.05, 'lng': -77.03, 'risk': 70.5},
          {'lat': -12.06, 'lng': -77.04, 'risk': 40.0},
        ],
      };

      final info = RiskInfo.fromJson(json);

      expect(info.district, 'Miraflores');
      expect(info.hour, 21);
      expect(info.riskScore, 72);
      expect(info.level, 'high');
      expect(info.topType, 'ROBBERY');
      expect(info.topSeverity, 'CRITICAL');
      expect(info.confidence, 'high');
      expect(info.badHours, [20, 21, 22]);
      expect(info.safestHours, [4, 5, 6]);
      expect(info.nearbyTiles, hasLength(2));
      expect(info.nearbyTiles.first.lat, -12.05);
      expect(info.nearbyTiles.first.risk, 70.5);
      expect(info.hasData, isTrue);
      expect(info.hasSafeHours, isTrue);
    });

    test('safestHours vacío cuando el motor no tiene señal horaria', () {
      final info = RiskInfo.fromJson({
        'district': 'Lurín',
        'hour': 10,
        'riskScore': 31,
        'level': 'low',
        'topType': null,
        'topSeverity': null,
        'confidence': 'low',
        'badHours': <int>[],
        'safestHours': <int>[],
        'nearbyTiles': <Map<String, dynamic>>[],
      });

      expect(info.safestHours, isEmpty);
      expect(info.hasSafeHours, isFalse);
    });

    test('DEGRADA si el API no manda safestHours/topSeverity (versión previa)', () {
      final info = RiskInfo.fromJson({
        'district': 'Miraflores',
        'hour': 21,
        'riskScore': 72,
        'level': 'high',
        'topType': 'ROBBERY',
        'confidence': 'high',
        'badHours': [20],
        'nearbyTiles': <Map<String, dynamic>>[],
      });

      expect(info.safestHours, isEmpty);
      expect(info.hasSafeHours, isFalse);
      expect(info.topSeverity, isNull);
      expect(info.hasData, isTrue);
    });

    test('parsea fail-open: riskScore null y level unknown', () {
      final json = {
        'district': 'San Isidro',
        'hour': 3,
        'riskScore': null,
        'level': 'unknown',
        'topType': null,
        'confidence': 'none',
        'badHours': <int>[],
        'nearbyTiles': <Map<String, dynamic>>[],
      };

      final info = RiskInfo.fromJson(json);

      expect(info.riskScore, isNull);
      expect(info.level, 'unknown');
      expect(info.topType, isNull);
      expect(info.badHours, isEmpty);
      expect(info.nearbyTiles, isEmpty);
      expect(info.hasData, isFalse);
    });
  });
}
