import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/incidents/data/models/incident_model.dart';

Map<String, dynamic> _baseJson() => <String, dynamic>{
      'id': 'inc-1',
      'type': 'ROBBERY',
      'severity': 'MODERATE',
      'status': 'ACTIVE',
      'lat': -12.05,
      'lng': -77.03,
      'district': 'Miraflores',
      'confirmCount': 2,
      'denyCount': 0,
      'reportCount': 3,
      'expiresAt': '2026-07-03T00:00:00.000Z',
      'createdAt': '2026-07-02T00:00:00.000Z',
      'updatedAt': '2026-07-02T00:00:00.000Z',
    };

void main() {
  group('IncidentModel.fromJson — aiScore/aiVerified', () {
    test('parsea aiScore y aiVerified cuando vienen presentes', () {
      final json = _baseJson()
        ..['aiScore'] = 0.85
        ..['aiVerified'] = true;

      final entity = IncidentModel.fromJson(json);

      expect(entity.aiScore, equals(0.85));
      expect(entity.aiVerified, isTrue);
    });

    test('aiScore/aiVerified son null cuando no vienen en el JSON', () {
      final entity = IncidentModel.fromJson(_baseJson());

      expect(entity.aiScore, isNull);
      expect(entity.aiVerified, isNull);
    });

    test('convierte aiScore num (int) a double', () {
      final json = _baseJson()
        ..['aiScore'] = 1
        ..['aiVerified'] = false;

      final entity = IncidentModel.fromJson(json);

      expect(entity.aiScore, equals(1.0));
      expect(entity.aiScore, isA<double>());
      expect(entity.aiVerified, isFalse);
    });
  });

  group('IncidentDetailModel.fromJson — aiScore/aiVerified', () {
    test('parsea aiScore y aiVerified cuando vienen presentes', () {
      final json = _baseJson()
        ..['aiScore'] = 0.42
        ..['aiVerified'] = false;

      final entity = IncidentDetailModel.fromJson(json);

      expect(entity.aiScore, equals(0.42));
      expect(entity.aiVerified, isFalse);
    });

    test('aiScore/aiVerified son null cuando no vienen en el JSON', () {
      final entity = IncidentDetailModel.fromJson(_baseJson());

      expect(entity.aiScore, isNull);
      expect(entity.aiVerified, isNull);
    });
  });
}
