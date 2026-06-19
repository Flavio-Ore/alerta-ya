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

export type AnalyzeFailureReason =
  | 'not_configured'
  | 'timeout'
  | 'provider_error'
  | 'empty_response';

export type AnalyzeResult =
  | { ok: true; answer: string }
  | { ok: false; reason: AnalyzeFailureReason };

export class GlmClientError extends Error {
  constructor(public readonly reason: AnalyzeFailureReason) {
    super(reason);
    this.name = 'GlmClientError';
  }
}

interface GlmStreamPayload {
  choices?: Array<{ delta?: { content?: string } }>;
}

function buildMessages(question: string, context: AnalyzeContext) {
  const top = context.districts
    .slice(0, 15)
    .map(
      (district, index) =>
        `${index + 1}. ${district.district}: riesgo ${district.risk}/100 (${district.count} denuncias)`,
    )
    .join('\n');
  const types = context.types
    .map((crimeType) => `- ${crimeType.type}: ${crimeType.count}`)
    .join('\n');

  const system = `
## Rol
Eres un analista de seguridad ciudadana que apoya a autoridades de Lima, Perú. Eres asesor: la autoridad conserva la decisión final.

## Fuentes y límites
- Tu fuente principal y única para cifras delictivas es el histórico DataCrim/INEI 2017–2020 entregado en el mensaje del usuario.
- Los datos permiten afirmar DÓNDE y QUÉ ocurrió, pero no a qué hora. Nunca infieras horarios.
- No inventes cifras, tendencias, causas, zonas ni comparaciones ausentes en los datos.
- Interpreta el puntaje de riesgo como un índice comparativo, nunca como probabilidad de que ocurra un delito.
- No clasifiques un puntaje como bajo, moderado o crítico si no recibiste umbrales explícitos.
- No calcules porcentajes o tasas salvo que el denominador esté identificado explícitamente como el total del dataset.
- Habla de denuncias registradas, no de víctimas, personas ni delitos confirmados.
- Usa búsqueda web solo cuando la pregunta necesite contexto actual verificable, como eventos, cierres viales o comunicados oficiales.
- Separa claramente **Histórico** de **Contexto actual**. El contexto web complementa; nunca reemplaza ni contradice el histórico.
- Si no existe evidencia suficiente, dilo de forma explícita y pide el dato necesario.

## Comportamiento conversacional
- Responde directamente, sin saludos ceremoniales ni frases de relleno.
- Si el usuario solo saluda, explica en una frase qué análisis puedes realizar y ofrece tres ejemplos breves.
- Prioriza información accionable, prudente y proporcional. No presentes recomendaciones como órdenes operativas.

## Formato de respuesta
Usa Markdown breve y legible, con un máximo de 220 palabras.
- Empieza con una conclusión de una o dos frases.
- Cuando aplique, usa encabezados Markdown de nivel 3 con estos títulos: Hallazgos, Evidencia histórica, Contexto actual y Recomendación operativa.
- Usa listas cortas para cifras o acciones. No generes tablas salvo que la comparación lo requiera.
- Todo dato web debe incluir un enlace Markdown a su fuente. Si no hay una fuente confiable, omite la sección de contexto actual.
`.trim();

  const user = `
## Datos históricos disponibles

### Ranking de riesgo por distrito
${top || 'Sin datos de distritos.'}

### Denuncias por tipo de delito
${types || 'Sin datos de tipos de delito.'}

## Pregunta de la autoridad
${question}
`.trim();

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}

function buildRequestBody(
  question: string,
  context: AnalyzeContext,
  stream: boolean,
) {
  const needsCurrentContext =
    /\b(hoy|actual|ahora|reciente|noticia|evento|marcha|cierre|tráfico|transito|tránsito|web|fuente)\b/i.test(
      question,
    );

  return {
    model: env.GLM_MODEL,
    temperature: 0.25,
    max_tokens: 700,
    stream,
    thinking: { type: 'disabled' },
    ...(needsCurrentContext
      ? { tools: [{ type: 'web_search', web_search: { enable: true } }] }
      : {}),
    messages: buildMessages(question, context),
  };
}

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
): Promise<AnalyzeResult> {
  if (!env.GLM_API_KEY) return { ok: false, reason: 'not_configured' };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), env.GLM_TIMEOUT_MS);

  try {
    const response = await fetch(env.GLM_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.GLM_API_KEY}`,
      },
      body: JSON.stringify(buildRequestBody(question, context, false)),
      signal: controller.signal,
    });

    if (!response.ok) {
      console.error('[GLM] provider error', { status: response.status });
      return { ok: false, reason: 'provider_error' };
    }

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const answer = data.choices?.[0]?.message?.content?.trim();
    return answer
      ? { ok: true, answer }
      : { ok: false, reason: 'empty_response' };
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      console.error('[GLM] request timed out', { timeoutMs: env.GLM_TIMEOUT_MS });
      return { ok: false, reason: 'timeout' };
    }

    console.error('[GLM] request failed', {
      errorName: error instanceof Error ? error.name : 'UnknownError',
    });
    return { ok: false, reason: 'provider_error' };
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Expone únicamente el contenido final del modelo; nunca transmite el razonamiento interno.
 * El stream de Z.AI usa SSE y termina con `data: [DONE]`.
 */
export async function* streamHistoricalData(
  question: string,
  context: AnalyzeContext,
  externalSignal?: AbortSignal,
): AsyncGenerator<string> {
  if (!env.GLM_API_KEY) throw new GlmClientError('not_configured');

  const controller = new AbortController();
  const abortFromExternal = () => controller.abort();
  externalSignal?.addEventListener('abort', abortFromExternal, { once: true });
  const timeout = setTimeout(() => controller.abort(), env.GLM_TIMEOUT_MS);
  let emittedContent = false;

  try {
    const response = await fetch(env.GLM_API_URL, {
      method: 'POST',
      headers: {
        Accept: 'text/event-stream',
        'Content-Type': 'application/json',
        Authorization: `Bearer ${env.GLM_API_KEY}`,
      },
      body: JSON.stringify(buildRequestBody(question, context, true)),
      signal: controller.signal,
    });

    if (!response.ok) {
      console.error('[GLM] streaming provider error', { status: response.status });
      throw new GlmClientError('provider_error');
    }

    if (!response.body) throw new GlmClientError('empty_response');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        buffer += decoder.decode(value, { stream: !done });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          const data = trimmed.slice(5).trim();
          if (data === '[DONE]') {
            if (!emittedContent) throw new GlmClientError('empty_response');
            return;
          }

          const payload = JSON.parse(data) as GlmStreamPayload;
          const content = payload.choices?.[0]?.delta?.content;
          if (!content) continue;

          emittedContent = true;
          yield content;
        }

        if (done) break;
      }
    } finally {
      reader.releaseLock();
    }

    if (!emittedContent) throw new GlmClientError('empty_response');
  } catch (error) {
    if (error instanceof GlmClientError) throw error;
    if (error instanceof Error && error.name === 'AbortError') {
      throw new GlmClientError('timeout');
    }

    console.error('[GLM] streaming request failed', {
      errorName: error instanceof Error ? error.name : 'UnknownError',
    });
    throw new GlmClientError('provider_error');
  } finally {
    clearTimeout(timeout);
    externalSignal?.removeEventListener('abort', abortFromExternal);
  }
}
