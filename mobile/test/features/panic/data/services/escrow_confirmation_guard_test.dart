import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/services/escrow_confirmation_guard.dart';

void main() {
  group('EscrowConfirmationGuard', () {
    test(
      'una tarea que resuelve tarde para una sesión vieja NO confirma la sesión nueva',
      () async {
        // Reproduce la race del hallazgo crítico: sesión A lanza un envío
        // de escrow lento (por ejemplo, con reintentos y backoff) que
        // todavía no resolvió cuando sesión B arranca. El guard se resetea
        // para B (resetFor), y CUANDO la tarea vieja de A finalmente
        // resuelve, su resultado no debe poder marcar como confirmada la
        // clave de B.
        final guard = EscrowConfirmationGuard();
        final sessionACompleter = Completer<bool>();

        guard.resetFor('session-A');
        // Sesión A lanza su envío en segundo plano (no se espera).
        unawaited(guard.submit('session-A', () => sessionACompleter.future));

        // Sesión A "stop()ea" sin confirmar uploads — su tarea de escrow
        // queda huérfana, todavía pendiente.
        expect(guard.confirmed, isFalse);

        // Una NUEVA sesión (B) arranca antes de que la tarea de A resuelva.
        guard.resetFor('session-B');
        expect(guard.confirmed, isFalse);

        // Sesión B confirma sus uploads e intenta su propio envío, que
        // queda pendiente (simulado con otro completer).
        final sessionBCompleter = Completer<bool>();
        final bFuture = guard.submit('session-B', () => sessionBCompleter.future);

        // Justo en este momento, la tarea VIEJA de la sesión A finalmente
        // resuelve con éxito.
        sessionACompleter.complete(true);
        await Future<void>.delayed(Duration.zero);

        // La resolución tardía de A NO debe haber marcado como confirmada
        // la sesión activa (que ahora es B).
        expect(
          guard.confirmed,
          isFalse,
          reason:
              'una tarea huérfana de una sesión vieja no debe poder confirmar la sesión nueva',
        );

        // Y el propio envío de B, cuando resuelve, sigue pudiendo marcar
        // la confirmación correctamente porque B sigue siendo la sesión
        // activa.
        sessionBCompleter.complete(true);
        final bResult = await bFuture;
        expect(bResult, isTrue);
        expect(guard.confirmed, isTrue);
      },
    );

    test(
      'submit() reutiliza la tarea en curso para la misma sesión en vez de duplicarla',
      () async {
        final guard = EscrowConfirmationGuard();
        guard.resetFor('session-1');

        var callCount = 0;
        final completer = Completer<bool>();
        Future<bool> submitFn() {
          callCount++;
          return completer.future;
        }

        // start() lanza el primer envío (sin esperar).
        final first = guard.submit('session-1', submitFn);

        // confirmUploadsAndClearKey() se llama mientras el primero sigue
        // en curso para la MISMA sesión — no debe disparar un segundo
        // submitFn().
        final second = guard.submit('session-1', submitFn);

        expect(callCount, 1, reason: 'no debe haber una segunda llamada de red concurrente');
        expect(identical(first, second), isTrue);

        completer.complete(true);
        expect(await first, isTrue);
        expect(await second, isTrue);
        expect(guard.confirmed, isTrue);
      },
    );

    test('una nueva llamada tras completarse la anterior sí reintenta (no queda pegada)', () async {
      final guard = EscrowConfirmationGuard();
      guard.resetFor('session-1');

      var callCount = 0;
      Future<bool> failingSubmitFn() async {
        callCount++;
        return false;
      }

      final firstResult = await guard.submit('session-1', failingSubmitFn);
      expect(firstResult, isFalse);
      expect(guard.confirmed, isFalse);

      // El primer intento ya terminó (falló). Un segundo llamado para la
      // misma sesión debe reintentar de verdad, no reutilizar el resultado
      // fallido indefinidamente.
      final secondResult = await guard.submit('session-1', () async {
        callCount++;
        return true;
      });

      expect(callCount, 2);
      expect(secondResult, isTrue);
      expect(guard.confirmed, isTrue);
    });

    test('resetFor descarta el estado confirmado de la sesión anterior', () async {
      final guard = EscrowConfirmationGuard();
      guard.resetFor('session-1');
      await guard.submit('session-1', () async => true);
      expect(guard.confirmed, isTrue);

      guard.resetFor('session-2');
      expect(guard.confirmed, isFalse);
    });
  });
}
