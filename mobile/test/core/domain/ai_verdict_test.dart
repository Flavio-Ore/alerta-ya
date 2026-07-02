import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/domain/ai_verdict.dart';

void main() {
  group('aiVerdict', () {
    test('score null -> notEvaluated', () {
      expect(aiVerdict(null, null), equals(AiVerdictState.notEvaluated));
    });

    test('score presente + verified=true -> verified', () {
      expect(aiVerdict(0.9, true), equals(AiVerdictState.verified));
    });

    test('score presente + verified=false -> suspicious', () {
      expect(aiVerdict(0.3, false), equals(AiVerdictState.suspicious));
    });

    test(
        'score presente + verified=null -> notEvaluated '
        '(null NO debe leerse como verificado)', () {
      expect(aiVerdict(0.5, null), equals(AiVerdictState.notEvaluated));
    });
  });

  group('aiVerdictText', () {
    test('notEvaluated -> texto humano, nunca porcentaje crudo', () {
      final text = aiVerdictText(null, null);
      expect(text, equals('Sin evaluar por IA'));
    });

    test('verified -> texto de confianza con porcentaje redondeado', () {
      final text = aiVerdictText(0.85, true);
      expect(text, contains('confiable'));
      expect(text, contains('85%'));
    });

    test('suspicious -> texto de revision, sin porcentaje crudo suelto', () {
      final text = aiVerdictText(0.3, false);
      expect(text, contains('revisión'));
    });

    test('score presente + verified=null -> nunca-en-blanco, notEvaluated', () {
      final text = aiVerdictText(0.5, null);
      expect(text, equals('Sin evaluar por IA'));
    });
  });
}
