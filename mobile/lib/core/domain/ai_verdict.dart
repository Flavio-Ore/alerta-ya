// Derivación del veredicto de IA (3 estados) — fuente única de verdad,
// compartida entre incident detail y "mis reportes".
// Espejo del util web `aiVerdict()` (web/src/features/incidents/utils/aiVerdict.ts):
// mismas reglas de 3 estados para que ambas plataformas coincidan.
//
// Reglas (NO tratar `aiVerified == null` como verificado):
//   score == null                          -> notEvaluated
//   score != null && aiVerified == true    -> verified
//   score != null && aiVerified == false   -> suspicious
//   score != null && aiVerified == null    -> notEvaluated
enum AiVerdictState { verified, suspicious, notEvaluated }

/// Deriva el estado de 3 valores desde (score, verified). Pura, sin efectos.
AiVerdictState aiVerdict(double? score, bool? verified) {
  if (score == null) return AiVerdictState.notEvaluated;
  if (verified == true) return AiVerdictState.verified;
  if (verified == false) return AiVerdictState.suspicious;
  return AiVerdictState.notEvaluated;
}

/// Texto humano ("por qué") para mostrar al ciudadano — NUNCA un porcentaje
/// crudo suelto. Reutilizable por incident detail (widget) y "mis reportes".
String aiVerdictText(double? score, bool? verified) {
  switch (aiVerdict(score, verified)) {
    case AiVerdictState.verified:
      final pct = (score! * 100).round();
      return 'Tu reporte se ve confiable ($pct%)';
    case AiVerdictState.suspicious:
      return 'Marcado para revisión';
    case AiVerdictState.notEvaluated:
      return 'Sin evaluar por IA';
  }
}
