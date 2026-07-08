/**
 * Política de votos de confirmación/negación — lógica pura (Fase J).
 *
 * Blindaje anti-manipulación: para que un voto ("sigue ahí" / "ya no está")
 * cuente, el votante debe estar físicamente cerca del incidente. Un actor remoto
 * no puede inflar ni tumbar incidentes desde otro lado de la ciudad.
 */
import { distanceMeters } from '../../../core/utils/geo.utils';
import { reputationTier } from '../application/reputation-tier';

/** Radio máximo (metros) dentro del cual un voto es válido. */
export const VOTE_PROXIMITY_RADIUS_METERS = 400;

/** Peso de un voto según el tier de reputación del votante. */
export const VOTE_WEIGHTS = { high: 2, medium: 1, low: 0.5 } as const;

/** Mínimo de votantes DISTINTOS que rechazan para poder cerrar por consenso. */
export const CLOSE_MIN_DISTINCT_DENIERS = 3;

/** Margen (en unidades de peso) que el rechazo debe superar a la confirmación. */
export const CLOSE_WEIGHT_MARGIN = 3;

/**
 * Peso del voto derivado del reputationScore del votante. Una cuenta nueva/baja
 * pesa poco; una confiable pesa más → un ataque Sybil de cuentas nuevas no alcanza
 * para tumbar (o inflar) un incidente.
 */
export function voteWeight(reputationScore: number): number {
  return VOTE_WEIGHTS[reputationTier(reputationScore)];
}

/**
 * ¿Se debe cerrar el incidente por consenso de rechazo?
 * Requiere AMBAS condiciones (anti-manipulación):
 *  1. rechazo ponderado supera a la confirmación por un margen, y
 *  2. al menos K votantes DISTINTOS lo rechazaron.
 * Así un actor solo (o pocas cuentas) no cierra un incidente real.
 */
export function shouldCloseByConsensus(
  weightedDeny: number,
  weightedConfirm: number,
  distinctDeniers: number,
): boolean {
  return (
    distinctDeniers >= CLOSE_MIN_DISTINCT_DENIERS &&
    weightedDeny > weightedConfirm + CLOSE_WEIGHT_MARGIN
  );
}

/** true si el votante está dentro del radio de proximidad del incidente. */
export function isWithinVoteRange(
  voterLat: number,
  voterLng: number,
  incidentLat: number,
  incidentLng: number,
  radiusMeters: number = VOTE_PROXIMITY_RADIUS_METERS,
): boolean {
  return distanceMeters(voterLat, voterLng, incidentLat, incidentLng) <= radiusMeters;
}
