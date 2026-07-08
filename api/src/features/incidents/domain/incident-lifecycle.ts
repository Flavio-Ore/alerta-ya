/**
 * Ciclo de vida del incidente — lógica pura, sin dependencias externas.
 *
 * Blindaje anti-manipulación (Fase J): una señal auto-declarada de "sigue ahí"
 * extiende la expiración del incidente. Sin tope, un actor malicioso podría
 * mantener vivo un incidente falso indefinidamente. `cappedExtendedExpiry` limita
 * la vida total del incidente a `maxLifeMinutes` desde su creación.
 */

/** Vida máxima de un incidente desde su creación (minutos). */
export const MAX_INCIDENT_LIFE_MINUTES = 90;

/**
 * Nueva expiración tras extender, con tope duro en createdAt + maxLifeMinutes.
 * Nunca devuelve una fecha más allá del tope, sin importar cuántas extensiones
 * se soliciten.
 */
export function cappedExtendedExpiry(
  currentExpiresAt: Date,
  createdAt: Date,
  extraMinutes: number,
  maxLifeMinutes: number = MAX_INCIDENT_LIFE_MINUTES,
): Date {
  const proposed = currentExpiresAt.getTime() + extraMinutes * 60_000;
  const hardCap = createdAt.getTime() + maxLifeMinutes * 60_000;
  return new Date(Math.min(proposed, hardCap));
}
