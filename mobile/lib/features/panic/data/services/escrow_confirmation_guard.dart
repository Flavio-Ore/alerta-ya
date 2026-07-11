/// Encapsula el estado de confirmación de escrow con reconocimiento de
/// sesión.
///
/// [AudioRecordingService] es `@lazySingleton` — una sola instancia vive
/// durante toda la vida de la app y se reutiliza en cada activación de
/// pánico. Sin este guard, el resultado de un envío de escrow en segundo
/// plano lanzado por una sesión vieja (que puede tardar varios segundos por
/// los reintentos con backoff) podría resolver DESPUÉS de que una sesión
/// nueva ya haya empezado, y terminar marcando como "confirmada" la clave
/// de la sesión nueva sin que su propio envío haya siquiera terminado.
///
/// Este guard resuelve dos problemas:
/// 1. Descarta el resultado de una tarea de envío que resuelve para una
///    sesión que ya no es la activa (`resetFor` invalida las tareas
///    anteriores).
/// 2. Evita envíos concurrentes duplicados para la misma sesión — si ya hay
///    un envío en curso, [submit] reutiliza esa misma tarea en lugar de
///    lanzar una nueva llamada de red.
class EscrowConfirmationGuard {
  String? _sessionId;
  bool _confirmed = false;
  Future<bool>? _inFlight;

  /// Si el escrow de la sesión activa ya fue confirmado.
  bool get confirmed => _confirmed;

  /// Reinicia el guard para una nueva sesión. Cualquier tarea en curso de
  /// la sesión anterior queda "huérfana": cuando resuelva, su resultado no
  /// podrá aplicarse porque [sessionId] ya no coincidirá con la sesión
  /// activa.
  void resetFor(String sessionId) {
    _sessionId = sessionId;
    _confirmed = false;
    _inFlight = null;
  }

  /// Lanza (o reutiliza) un intento de envío de escrow para [sessionId].
  ///
  /// - Si ya hay un envío en curso para la MISMA sesión, se devuelve esa
  ///   misma tarea en lugar de lanzar una nueva (evita duplicar llamadas de
  ///   red al backend de escrow).
  /// - El resultado solo se aplica a [confirmed] si [sessionId] sigue
  ///   siendo la sesión activa en el momento en que la tarea resuelve —
  ///   si mientras tanto se llamó a [resetFor] con otra sesión, el
  ///   resultado se descarta.
  Future<bool> submit(String sessionId, Future<bool> Function() submitFn) {
    final existing = _inFlight;
    if (existing != null && _sessionId == sessionId) {
      return existing;
    }

    late final Future<bool> future;
    future = submitFn().then((confirmed) {
      if (_sessionId == sessionId) {
        _confirmed = confirmed;
      }
      // Solo limpiar _inFlight si sigue siendo esta misma tarea — evita
      // pisar una tarea más nueva lanzada mientras esta corría.
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
      return confirmed;
    });
    _inFlight = future;
    return future;
  }
}
