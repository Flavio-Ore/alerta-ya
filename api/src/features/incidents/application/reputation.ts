/**
 * Delta de reputación según resultado de verificación ML.
 * Lógica pura — sin dependencias externas.
 */
export type ReputationDelta = 5 | 3 | -1 | -2;

export const REPUTATION_DELTAS = {
  VERIFIED_WITH_EVIDENCE: 5,
  VERIFIED_NO_EVIDENCE: 3,
  SUSPICIOUS_WITH_EVIDENCE: -1,
  SUSPICIOUS_NO_EVIDENCE: -2,
} as const satisfies Record<string, ReputationDelta>;

/**
 * Calcula el delta de reputación a aplicar al reportante.
 *
 * @param verified   true si el verificador ML marcó el reporte como coherente
 * @param hasEvidence true si el reporte incluye al menos un archivo de media
 * @returns delta a sumar/restar al reputationScore (puede ser negativo)
 */
export function computeReputationDelta(verified: boolean, hasEvidence: boolean): ReputationDelta {
  if (verified && hasEvidence) return REPUTATION_DELTAS.VERIFIED_WITH_EVIDENCE;
  if (verified && !hasEvidence) return REPUTATION_DELTAS.VERIFIED_NO_EVIDENCE;
  if (!verified && hasEvidence) return REPUTATION_DELTAS.SUSPICIOUS_WITH_EVIDENCE;
  return REPUTATION_DELTAS.SUSPICIOUS_NO_EVIDENCE;
}
