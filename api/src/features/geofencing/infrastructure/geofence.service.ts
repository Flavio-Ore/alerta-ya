import Redis from "ioredis";

import { isWithinLima, getDistrict } from "../../../core/utils/geo.utils";

export { isWithinLima, getDistrict };

const ALERT_COOLDOWN_SECONDS = 180;

// Verifica si un usuario puede recibir una alerta para un distrito específico, aplicando un cooldown para evitar alertas repetitivas.
export async function acquireAlertCooldown(
  userId: string,
  district: string,
  redis: Redis,
): Promise<boolean> {
  const key = `geofence:${userId}:${district}`;
  const result = await redis.set(key, "1", "EX", ALERT_COOLDOWN_SECONDS, "NX");
  return result === "OK";
}
