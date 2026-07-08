import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/widgets/ai_verdict_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AiVerdictBadge', () {
    testWidgets('estado verified — icono check + label + color brand-blue',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AiVerdictBadge(score: 0.9, verified: true)),
      );

      expect(find.text('Confiable'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.verified));
      expect(icon.color, equals(AppColors.aiVerified));
    });

    testWidgets('estado suspicious — icono warn + label + color dedicado',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AiVerdictBadge(score: 0.3, verified: false)),
      );

      expect(find.text('Por revisar'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_maybe), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.gpp_maybe));
      expect(icon.color, equals(AppColors.aiSuspicious));
      // El warn de IA NUNCA debe compartir color con severidad moderada.
      expect(icon.color, isNot(equals(AppColors.severityModerate)));
    });

    testWidgets(
        'estado not-evaluated (null) — nunca en blanco, label neutral',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AiVerdictBadge(score: null, verified: null)),
      );

      expect(find.text('Sin evaluar'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets(
        'regression guard: verified=null con score presente NUNCA se '
        'lee como verificado', (tester) async {
      await tester.pumpWidget(
        _wrap(const AiVerdictBadge(score: 0.5, verified: null)),
      );

      expect(find.text('Sin evaluar'), findsOneWidget);
      expect(find.text('Confiable'), findsNothing);
    });
  });
}
