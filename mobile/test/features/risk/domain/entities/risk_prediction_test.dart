import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';

void main() {
  group('RiskPrediction.fromJson', () {
    test('parsea una predicción disponible del API', () {
      final p = RiskPrediction.fromJson({
        'available': true,
        'riskScore': 100,
        'expectedCount': 2.651,
        'confidence': 1.0,
        'hour': 23,
        'dayOfWeek': 5,
      });
      expect(p.available, isTrue);
      expect(p.riskScore, 100);
      expect(p.expectedCount, 2.651);
      expect(p.dayOfWeek, 5);
    });

    test('parsea available:false (ML degradado) sin score', () {
      final p = RiskPrediction.fromJson({
        'available': false,
        'hour': 10,
        'dayOfWeek': 2,
      });
      expect(p.available, isFalse);
      expect(p.riskScore, isNull);
      expect(p.dayOfWeek, 2);
    });

    test('DEGRADA si falta el campo available (nunca lanza)', () {
      final p = RiskPrediction.fromJson({'hour': 0, 'dayOfWeek': 0});
      expect(p.available, isFalse);
    });
  });

  test('factory unavailable arma el estado vacío', () {
    final p = RiskPrediction.unavailable(hour: 21, dayOfWeek: 4);
    expect(p.available, isFalse);
    expect(p.hour, 21);
    expect(p.dayOfWeek, 4);
    expect(p.riskScore, isNull);
  });
}
