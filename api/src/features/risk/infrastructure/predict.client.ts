import { env } from '../../../core/config/env';

/**
 * Cliente del predictor ML (XGBoost Poisson) — ML service POST /predict/risk.
 * Predice el riesgo por ubicación, hora y día de semana. A diferencia del motor
 * determinístico (/risk), este SÍ distingue día de semana.
 *
 * Fail-open: cualquier error (timeout, red, 5xx, modelo degradado) → null.
 * El caller decide cómo mostrar la ausencia; nunca lanza.
 */
export interface PredictInput {
  lat: number;
  lng: number;
  hour: number;
  dayOfWeek: number; // 0=lunes ... 6=domingo (contrato del modelo)
}

export interface PredictResult {
  riskScore: number; // 0-100
  expectedCount: number; // λ del modelo Poisson
  confidence: number; // 0-1
  hour: number;
  dayOfWeek: number;
}

const PREDICT_TIMEOUT_MS = 1200;

export async function predictRisk(input: PredictInput): Promise<PredictResult | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PREDICT_TIMEOUT_MS);

  try {
    const response = await fetch(`${env.ML_SERVICE_URL}/predict/risk`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        lat: input.lat,
        lng: input.lng,
        hour: input.hour,
        day_of_week: input.dayOfWeek,
      }),
      signal: controller.signal,
    });

    if (!response.ok) return null;

    const data = (await response.json()) as {
      risk_score: number;
      expected_count: number;
      confidence: number;
      predicted_hour: number;
      day_of_week: number;
      degraded: boolean;
    };

    // Modelo sin cargar en el ML service → tratamos como sin dato (fail-open).
    if (data.degraded) return null;

    return {
      riskScore: data.risk_score,
      expectedCount: data.expected_count,
      confidence: data.confidence,
      hour: data.predicted_hour,
      dayOfWeek: data.day_of_week,
    };
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}
