import { getMessaging } from "firebase-admin/messaging";
import Redis from "ioredis";

import { PublicIncidentDTO } from "../../incidents/domain/entities/incident.entity";

const PUSH_COOLDOWN_SECONDS = 180;

export interface ConfirmRequestPushData {
  zoneLabel: string;
  type: string;
  approxLat: number;
  approxLng: number;
  reportedAt: string;
}

/**
 * Push para confirm-request — pide a vecinos cercanos confirmar un primer reporte
 * sin incidente publicado todavía. Body: "Posible robo en Av. Larco · ¿lo viste?"
 * Cooldown corto (60s) por token para no spamear si llegan muchos reportes seguidos.
 */
export async function sendConfirmRequestPush(
  data: ConfirmRequestPushData,
  tokens: string[],
  redis: Redis,
  streetAddress?: string | null,
): Promise<SendPushResult> {
  const result: SendPushResult = { sent: 0, skippedCooldown: 0, failed: 0, invalidTokens: [] };
  if (tokens.length === 0) return result;

  const eligibleTokens: string[] = [];
  for (const token of tokens) {
    // Cooldown más corto que el de incidente (60s) — confirm-request es más efímero.
    const cooldownKey = `rate:push:confirmreq:${token}:${data.zoneLabel}:${data.type}`;
    const acquired = await redis.set(cooldownKey, "1", "EX", 60, "NX");
    if (acquired === "OK") {
      eligibleTokens.push(token);
    } else {
      result.skippedCooldown++;
    }
  }
  if (eligibleTokens.length === 0) return result;

  const location = streetAddress
    ? `${streetAddress}, ${data.zoneLabel}`
    : data.zoneLabel;
  const notification = {
    title: "AlertaYa | Por confirmar en tu zona",
    body: `${data.type} en ${location} — ¿lo viste?`,
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: eligibleTokens,
      notification,
      data: {
        // Tipo discriminator — el mobile usa esto para abrir el sheet correcto.
        type: "confirm-request",
        zoneLabel: data.zoneLabel,
        incidentType: data.type,
        approxLat: data.approxLat.toString(),
        approxLng: data.approxLng.toString(),
        reportedAt: data.reportedAt,
      },
    });
    result.sent = response.successCount;
    result.failed = response.failureCount;
    inspectResponses(response.responses, eligibleTokens, result);
  } catch (err) {
    result.failed = eligibleTokens.length;
    console.error(
      '[FCM] sendEachForMulticast lanzó (confirm-request):',
      err instanceof Error ? `${err.name}: ${err.message}` : err,
    );
  }

  return result;
}

export interface SendPushResult {
  sent: number;
  skippedCooldown: number;
  failed: number;
  /** Tokens que FCM rechazó como no registrados/inválidos — el caller debe borrarlos. */
  invalidTokens: string[];
}

/** Códigos de FCM que indican un token muerto (app desinstalada, token rotado). */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Registra el error real de cada token fallido y acumula los tokens muertos.
 * Sin esto los fallos de FCM quedaban invisibles (solo un contador).
 */
function inspectResponses(
  responses: { success: boolean; error?: { code: string; message: string } }[],
  tokens: string[],
  result: SendPushResult,
): void {
  responses.forEach((r, i) => {
    if (r.success || !r.error) return;
    console.error(
      `[FCM] token ${tokens[i].slice(0, 8)}… falló: ${r.error.code} — ${r.error.message}`,
    );
    if (DEAD_TOKEN_CODES.has(r.error.code)) result.invalidTokens.push(tokens[i]);
  });
}

export async function sendIncidentPush(
  incident: PublicIncidentDTO,
  tokens: string[],
  redis: Redis,
  streetAddress?: string | null,
): Promise<SendPushResult> {
  const result: SendPushResult = { sent: 0, skippedCooldown: 0, failed: 0, invalidTokens: [] };
  if (tokens.length === 0) return result;

  const eligibleTokens: string[] = [];

  for (const token of tokens) {
    const cooldownKey = `rate:push:token:${token}:${incident.district}:${incident.type}`;
    const acquired = await redis.set(
      cooldownKey,
      "1",
      "EX",
      PUSH_COOLDOWN_SECONDS,
      "NX",
    );
    if (acquired === "OK") {
      eligibleTokens.push(token);
    } else {
      result.skippedCooldown++;
    }
  }

  if (eligibleTokens.length === 0) return result;

  // Payload anónimo — calle aproximada (si disponible), distrito y cantidad.
  // NUNCA coordenadas exactas ni identidad del reportante.
  const location = streetAddress
    ? `${streetAddress}, ${incident.district}`
    : incident.district;
  const notification = {
    title: "AlertaYa | Alerta en tu zona",
    body: `${incident.type} en ${location} — ${incident.reportCount} reportes`,
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: eligibleTokens,
      notification,
      data: {
        incidentId: incident.id,
        severity: incident.severity,
        district: incident.district,
        type: incident.type,
      },
    });

    result.sent = response.successCount;
    result.failed = response.failureCount;
    inspectResponses(response.responses, eligibleTokens, result);
  } catch (err) {
    result.failed = eligibleTokens.length;
    console.error(
      '[FCM] sendEachForMulticast lanzó (incident):',
      err instanceof Error ? `${err.name}: ${err.message}` : err,
    );
  }

  return result;
}
