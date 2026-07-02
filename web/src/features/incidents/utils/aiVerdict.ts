/** Estado derivado del verificador IA. Fuente única de verdad de la lógica 3-estados. */
export type AiState = 'verified' | 'suspicious' | 'not-evaluated';

/**
 * Deriva el estado 3-estados a partir de (aiScore, aiVerified).
 * - score == null                     -> not-evaluated (la IA no corrió)
 * - score != null AND verified===true  -> verified
 * - score != null AND verified===false -> suspicious
 * - score != null AND verified==null   -> not-evaluated (FIX: null ya no se comporta como verified)
 */
export function aiVerdict(
  score?: number | null,
  verified?: boolean | null,
): AiState {
  if (score == null) return 'not-evaluated';
  if (verified === true) return 'verified';
  if (verified === false) return 'suspicious';
  return 'not-evaluated';
}
