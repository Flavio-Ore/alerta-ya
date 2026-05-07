import Redis from "ioredis";

const SUSPECT_TTL_SECONDS = 20 * 60;
const SUSPECT_SCORE_THRESHOLD = 0.3;

// Aplica una penalización a un reporte si su score de sospecha es menor al umbral definido, marcándolo como sospechoso en Redis por un tiempo determinado.
export async function applyMlPenalty(
  reportId: string,
  score: number,
  redis: Redis,
): Promise<void> {
  if (score >= SUSPECT_SCORE_THRESHOLD) return;

  const key = `suspect:${reportId}`;
  await redis.set(key, "1", "EX", SUSPECT_TTL_SECONDS);
}

export async function isReportSuspect(
  reportId: string,
  redis: Redis,
): Promise<boolean> {
  const val = await redis.get(`suspect:${reportId}`);
  return val !== null;
}
