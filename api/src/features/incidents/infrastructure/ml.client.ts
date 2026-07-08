import { env } from '../../../core/config/env';

/** Umbral para derivar aiVerified desde el finalScore del pipeline ML + visión. */
export const AI_VERIFIED_THRESHOLD = 0.5;

export interface MlVerifyInput {
  reportId: string;
  lat: number;
  lng: number;
  type: string;
  formData: Record<string, unknown>;
  userReputation: number;
  hasEvidence: boolean;
  photoAgeMinutes: number | null;
  /**
   * 'exif' | 'device_clock' | null — informativo, forward-compat para el
   * verificador ML (S4). El ML actual ignora campos desconocidos (pydantic
   * extra='ignore'), así que esto NUNCA gatea/bloquea el resultado hoy.
   */
  photoSource: string | null;
}

export interface MlVerifyResult {
  score: number;
  verified: boolean;
}

const ML_TIMEOUT_MS = 800;

export async function verifyReport(input: MlVerifyInput): Promise<MlVerifyResult | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), ML_TIMEOUT_MS);

  try {
    const response = await fetch(`${env.ML_SERVICE_URL}/ml/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // NUNCA incluir userId — solo reputación
      body: JSON.stringify({
        report_id: input.reportId,
        lat: input.lat,
        lng: input.lng,
        type: input.type,
        form_data: input.formData,
        user_reputation: input.userReputation,
        has_evidence: input.hasEvidence,
        photo_age_minutes: input.photoAgeMinutes,
        photo_source: input.photoSource,
      }),
      signal: controller.signal,
    });

    if (!response.ok) return null;

    const data = (await response.json()) as { score: number; verified: boolean };
    return { score: data.score, verified: data.verified };
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}
