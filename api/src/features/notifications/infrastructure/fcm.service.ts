import { getMessaging } from "firebase-admin/messaging";
import Redis from "ioredis";

import { PublicIncidentDTO } from "../../incidents/domain/entities/incident.entity";

const PUSH_COOLDOWN_SECONDS = 180;

export interface SendPushResult {
  sent: number;
  skippedCooldown: number;
  failed: number;
}

export async function sendIncidentPush(
  incident: PublicIncidentDTO,
  tokens: string[],
  redis: Redis,
  streetAddress?: string | null,
): Promise<SendPushResult> {
  const result: SendPushResult = { sent: 0, skippedCooldown: 0, failed: 0 };
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
  } catch {
    result.failed = eligibleTokens.length;
  }

  return result;
}
