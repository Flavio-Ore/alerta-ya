import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/my_reports/data/models/my_report_model.dart';

Map<String, dynamic> _baseJson() => <String, dynamic>{
      'id': 'inc-1',
      'status': 'ACTIVE',
      'severity': 'MODERATE',
      'district': 'Miraflores',
      'confirmCount': 1,
      'denyCount': 0,
      'reportCount': 1,
      'expiresAt': '2026-07-03T00:00:00.000Z',
      'updatedAt': '2026-07-02T00:00:00.000Z',
    };

void main() {
  group('MyReportIncidentModel.fromJson — aiScore/aiVerified', () {
    test('parsea aiScore y aiVerified cuando vienen presentes', () {
      final json = _baseJson()
        ..['aiScore'] = 0.85
        ..['aiVerified'] = true;

      final incident = MyReportIncidentModel.fromJson(json);

      expect(incident.aiScore, equals(0.85));
      expect(incident.aiVerified, isTrue);
    });

    test(
        'aiScore/aiVerified son null cuando el backend aun no los envia '
        '(tolerante, PR1c los agrega despues)', () {
      final incident = MyReportIncidentModel.fromJson(_baseJson());

      expect(incident.aiScore, isNull);
      expect(incident.aiVerified, isNull);
    });
  });
}
