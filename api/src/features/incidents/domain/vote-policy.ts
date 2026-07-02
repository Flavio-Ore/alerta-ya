/**
 * Política de votos de confirmación/negación — lógica pura (Fase J).
 *
 * Blindaje anti-manipulación: para que un voto ("sigue ahí" / "ya no está")
 * cuente, el votante debe estar físicamente cerca del incidente. Un actor remoto
 * no puede inflar ni tumbar incidentes desde otro lado de la ciudad.
 */
import { distanceMeters } from '../../../core/utils/geo.utils';

/** Radio máximo (metros) dentro del cual un voto es válido. */
export const VOTE_PROXIMITY_RADIUS_METERS = 400;

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
