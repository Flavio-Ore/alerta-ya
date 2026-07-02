import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/incidents/data/models/incident_model.dart';

Map<String, dynamic> _baseDetailJson() => {
      'id': 'inc-1',
      'type': 'ROBBERY',
      'severity': 'MODERATE',
      'status': 'ACTIVE',
      'lat': -12.05,
      'lng': -77.03,
      'district': 'Miraflores',
      'confirmCount': 3,
      'denyCount': 0,
      'reportCount': 3,
      'expiresAt': '2024-01-15T02:00:00.000Z',
      'createdAt': '2024-01-15T00:00:00.000Z',
      'updatedAt': '2024-01-15T00:00:00.000Z',
    };

void main() {
  group('IncidentDetailModel.fromJson', () {
    test('mapea reporterTrust cuando está presente en el JSON', () {
      final json = {..._baseDetailJson(), 'reporterTrust': 'high'};

      final detail = IncidentDetailModel.fromJson(json);

      expect(detail.reporterTrust, equals('high'));
    });

    test('reporterTrust es null cuando no viene en el JSON', () {
      final json = _baseDetailJson();

      final detail = IncidentDetailModel.fromJson(json);

      expect(detail.reporterTrust, isNull);
    });
  });
}
