import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_dashboard_page.dart';

void main() {
  group('riskVerdictFor', () {
    test('nivel high devuelve mensaje de alerta crítica', () {
      final verdict = riskVerdictFor('high');
      expect(verdict.message, contains('ALTO'));
      expect(verdict.color, AppColors.severityCritical);
    });

    test('nivel moderate devuelve mensaje de alerta moderada', () {
      final verdict = riskVerdictFor('moderate');
      expect(verdict.message, 'Riesgo moderado — mantente alerta');
      expect(verdict.color, AppColors.severityModerate);
    });

    test('nivel low devuelve mensaje de riesgo bajo', () {
      final verdict = riskVerdictFor('low');
      expect(verdict.message, 'Riesgo bajo');
      expect(verdict.color, AppColors.severityLow);
    });

    test('nivel desconocido devuelve mensaje de datos insuficientes', () {
      final verdict = riskVerdictFor('unknown');
      expect(verdict.message, 'Sin datos suficientes para esta zona');
      expect(verdict.color, AppColors.onSurfaceVariant);
    });
  });
}
