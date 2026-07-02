/**
 * Tier de reputación — lógica pura, sin dependencias externas.
 *
 * PRIVACIDAD: el `reputationScore` numérico NUNCA se expone a otros usuarios.
 * A terceros solo llega un tier grueso de 3 niveles (`ReputationTier`), que da
 * seguridad al lector sin revelar identidad ni puntaje. El puntaje exacto solo
 * lo ve su propio dueño vía GET /me (ver `ownerReputationLevel`).
 */

export type ReputationTier = 'high' | 'medium' | 'low';

/** Umbrales sobre reputationScore (default 100). */
export const TIER_THRESHOLDS = {
  /** >= HIGH → historial verificado sostenido */
  HIGH: 115,
  /** < LOW → historial neto negativo (reportes dudosos) */
  LOW: 90,
} as const;

/**
 * Mapea un reputationScore al tier anónimo de 3 niveles visible a otros usuarios.
 * No revela el número: solo la banda.
 */
export function reputationTier(score: number): ReputationTier {
  if (score >= TIER_THRESHOLDS.HIGH) return 'high';
  if (score < TIER_THRESHOLDS.LOW) return 'low';
  return 'medium';
}

/**
 * Tier agregado de un incidente a partir de los reputationScore de sus
 * reportantes. Usa el PROMEDIO (no el máximo) para que una sola cuenta de
 * reputación alta no infle la confianza de un incidente colectivo.
 *
 * @returns el tier del promedio, o null si no hay reportantes conocidos.
 */
export function aggregateReporterTier(scores: number[]): ReputationTier | null {
  if (scores.length === 0) return null;
  const avg = scores.reduce((sum, s) => sum + s, 0) / scores.length;
  return reputationTier(avg);
}

export interface OwnerReputationLevel {
  /** Tier grueso (mismo que ven terceros). */
  tier: ReputationTier;
  /** Puntaje exacto — solo visible al dueño. */
  score: number;
  /** Puntos hasta el siguiente tier; null si ya está en 'high'. */
  pointsToNext: number | null;
}

/**
 * Nivel personal detallado — solo para el propio usuario (GET /me).
 * A diferencia del tier público, aquí sí se incluye el puntaje.
 */
export function ownerReputationLevel(score: number): OwnerReputationLevel {
  const tier = reputationTier(score);
  let pointsToNext: number | null;
  if (tier === 'low') pointsToNext = TIER_THRESHOLDS.LOW - score;
  else if (tier === 'medium') pointsToNext = TIER_THRESHOLDS.HIGH - score;
  else pointsToNext = null;
  return { tier, score, pointsToNext };
}
