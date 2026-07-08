import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/report/data/models/report_submit_result_model.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';

void main() {
  group('ReportSubmitResultModel.fromResponse', () {
    test('parsea reputationDelta int positivo desde respuesta 200', () {
      // Usamos 200 para evitar parsear IncidentModel (requiere fixture complejo)
      final result = ReportSubmitResultModel.fromResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'incident': null,
          'reputationDelta': 5,
        },
      );

      expect(result.isPublished, isFalse);
      expect(result.reputationDelta, equals(5));
    });

    test('parsea reputationDelta negativo desde respuesta 200', () {
      final result = ReportSubmitResultModel.fromResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'incident': null,
          'reputationDelta': -2,
        },
      );

      expect(result.isPublished, isFalse);
      expect(result.reputationDelta, equals(-2));
    });

    test('reputationDelta es null cuando no viene en la respuesta', () {
      final result = ReportSubmitResultModel.fromResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'incident': null,
        },
      );

      expect(result.isPublished, isFalse);
      expect(result.reputationDelta, isNull);
    });

    test('convierte reputationDelta num a int (ej. double del JSON)', () {
      final result = ReportSubmitResultModel.fromResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'incident': null,
          'reputationDelta': 3.0,
        },
      );

      expect(result.reputationDelta, equals(3));
      expect(result.reputationDelta, isA<int>());
    });

    test('isPublished false cuando statusCode es 200 sin incident', () {
      final result = ReportSubmitResultModel.fromResponse(
        statusCode: 200,
        body: <String, dynamic>{'incident': null},
      );

      expect(result.isPublished, isFalse);
      expect(result.incident, isNull);
    });

    test('copyWith preserva reputationDelta en ReportSubmitResult', () {
      const original = ReportSubmitResult(
        isPublished: false,
        reputationDelta: 3,
      );
      final copy = original.copyWith(isPublished: true);

      expect(copy.reputationDelta, equals(3));
      expect(copy.isPublished, isTrue);
    });
  });
}
