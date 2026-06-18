import { env } from "../../../core/config/env";

export interface RiskDistrict {
  district: string;
  risk: number;
  count: number;
}

export interface CrimeTypeStat {
  type: string;
  count: number;
}

export interface AnalyzeContext {
  districts: RiskDistrict[];
  types: CrimeTypeStat[];
}

const GLM_TIMEOUT_MS = 20000;

/**
 * Asistente de análisis para autoridades, anclado (grounded) a la data histórica REAL.
 *
 * Seguridad/honestidad:
 *  - La key vive solo en el backend.
 *  - Se le pasa SOLO la data histórica provista (rankings, tipos) — sin PII.
 *  - Se instruye a GLM a responder ÚNICAMENTE con esos datos y a no inventar.
 *  - Es asesor: la autoridad decide. Datos solo a nivel AÑO (dónde, no a qué hora).
 * Fail-open: devuelve null si no hay key o si GLM falla.
 */
export async function analyzeHistoricalData(
  question: string,
  context: AnalyzeContext,
): Promise<string | null> {
  if (!env.GLM_API_KEY) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GLM_TIMEOUT_MS);

  const top = context.districts
    .slice(0, 15)
    .map(
      (d, i) =>
        `${i + 1}. ${d.district}: riesgo ${d.risk}/100 (${d.count} denuncias)`,
    )
    .join("\n");
  const types = context.types.map((t) => `- ${t.type}: ${t.count}`).join("\n");

  const system =
    "Eres un analista de seguridad ciudadana para autoridades de Lima, Perú. " +
    "Tu BASE son los datos históricos provistos (denuncias DataCrim/INEI 2017–2020). " +
    "Puedes usar búsqueda web SOLO para contexto ACTUAL y factual relevante a seguridad " +
    "(marchas o eventos programados, cierres de vías, situación pública reciente del distrito). " +
    "Reglas estrictas: " +
    "(1) NO inventes cifras de delitos ni zonas que no estén en los datos. " +
    '(2) DISTINGUE SIEMPRE la fuente: marca "[Histórico]" para conclusiones de los datos y ' +
    '"[Contexto actual — web, sin verificar]" para lo que venga de la búsqueda. ' +
    "(3) Una noticia NUNCA reemplaza ni contradice una conclusión de los datos: solo agrega contexto. " +
    "(4) Si la web no aporta nada confiable, omte esa parte. " +
    "(5) Los datos NO tienen hora del día: habla de DÓNDE, nunca de a qué hora. " +
    "(6) Eres asesor, la autoridad decide. Responde breve, en español, máximo 200 palabras." +
    "(7) Realiza búsquedas de fuentes confiables si es necesario para brindar información más detallada." +
    "(8) Si es necesario al último del mensaje brinda una recomendación sobre lo que deberia realizar la autoridad respecto al caso que te pregunte y en base a los valores perfectos de una autoridad.";

  const user =
    `Ranking de riesgo por distrito:\n${top}\n\n` +
    `Denuncias por tipo de delito:\n${types}\n\n` +
    `Pregunta de la autoridad: ${question}`;

  try {
    const response = await fetch(env.GLM_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.GLM_API_KEY}`,
      },
      body: JSON.stringify({
        model: env.GLM_MODEL,
        temperature: 0.4,
        max_tokens: 700,
        // Búsqueda web nativa de GLM — el modelo la usa solo si hace falta contexto actual.
        tools: [{ type: "web_search", web_search: { enable: true } }],
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
      signal: controller.signal,
    });

    if (!response.ok) return null;

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    return data.choices?.[0]?.message?.content?.trim() ?? null;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}
