import { API_BASE_URL } from "../../../core/constants/api";
import { firebaseAuthRepository } from "../../auth/infrastructure/firebase-auth.repository";

const configuredTimeout = Number(import.meta.env.VITE_AI_TIMEOUT_MS);
const AI_TIMEOUT_MS =
  Number.isFinite(configuredTimeout) && configuredTimeout >= 1_000
    ? configuredTimeout
    : 65_000;

export interface AnalyzeContext {
  districts: { district: string; risk: number; count: number }[];
  types: { type: string; count: number }[];
}

interface StreamAnalyzeOptions {
  question: string;
  context: AnalyzeContext;
  signal?: AbortSignal;
  onDelta: (content: string) => void;
}

interface StreamEventPayload {
  content?: string;
  message?: string;
}

export async function streamAnalyze({
  question,
  context,
  signal,
  onDelta,
}: StreamAnalyzeOptions): Promise<void> {
  const token = await firebaseAuthRepository.getIdToken();
  const controller = new AbortController();
  const abortFromCaller = () => controller.abort();
  signal?.addEventListener("abort", abortFromCaller, { once: true });
  const timeout = window.setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

  try {
    const response = await fetch(`${API_BASE_URL}/ai/analyze-stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/event-stream",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ question, context }),
      signal: controller.signal,
    });

    if (response.status === 401) {
      await firebaseAuthRepository.signOut();
      window.location.href = "/auth/login";
      throw new Error("Tu sesión expiró. Inicia sesión nuevamente.");
    }

    if (!response.ok || !response.body) {
      const data = (await response.json().catch(() => null)) as {
        error?: { message?: string };
      } | null;
      throw new Error(
        data?.error?.message ?? "No se pudo conectar con el asistente IA.",
      );
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      buffer += decoder.decode(value, { stream: !done });
      const frames = buffer.split(/\r?\n\r?\n/);
      buffer = frames.pop() ?? "";

      for (const frame of frames) {
        const lines = frame.split(/\r?\n/);
        const event = lines
          .find((line) => line.startsWith("event:"))
          ?.slice(6)
          .trim();
        const data = lines
          .filter((line) => line.startsWith("data:"))
          .map((line) => line.slice(5).trim())
          .join("\n");

        if (!data) continue;
        const payload = JSON.parse(data) as StreamEventPayload;

        if (event === "delta" && payload.content) onDelta(payload.content);
        if (event === "error") {
          throw new Error(
            payload.message ?? "El asistente IA no pudo responder.",
          );
        }
        if (event === "done") return;
      }

      if (done) return;
    }
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      if (signal?.aborted) throw new Error("Respuesta detenida.");
      throw new Error("La IA tardó demasiado en responder. Intenta nuevamente.");
    }
    throw error;
  } finally {
    window.clearTimeout(timeout);
    signal?.removeEventListener("abort", abortFromCaller);
  }
}
