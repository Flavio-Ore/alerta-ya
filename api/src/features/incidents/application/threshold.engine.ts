import Redis from "ioredis";

import { Severity } from "../domain/entities/incident.entity";
import { RobberyForm, AccidentForm } from "../domain/entities/report.entity";
import { bucketCoord } from "../../../core/utils/geo.utils";

const WINDOW_15_MIN_MS = 15 * 60 * 1000;
const WINDOW_20_MIN_SECONDS = 20 * 60;

export interface ThresholdContext {
  lat: number;
  lng: number;
  type: string;
  reportId: string;
  formData: RobberyForm | AccidentForm | Record<string, unknown>;
  now: number;
}

export interface ThresholdDecision {
  publish: boolean;
  severity?: Severity;
  push?: boolean;
  alertPolice?: boolean;
  extendExpiryMinutes?: number;
}

function extractFormFlags(
  formData: RobberyForm | AccidentForm | Record<string, unknown>,
): {
  weapon: boolean;
  injured: boolean;
  stillHere: boolean;
} {
  const d = formData as Record<string, unknown>;
  return {
    weapon: d["weapon"] === true,
    injured: d["injured"] === true,
    stillHere: d["stillInArea"] === true,
  };
}

export async function evaluateThreshold(
  ctx: ThresholdContext,
  redis: Redis,
): Promise<ThresholdDecision> {
  const bucketLat = bucketCoord(ctx.lat);
  const bucketLng = bucketCoord(ctx.lng);
  const key = `threshold:${bucketLat}:${bucketLng}:${ctx.type}`;
  const flags = extractFormFlags(ctx.formData);

  const pipeline = redis.pipeline();
  // HSETNX solo establece firstAt si no existe, para marcar el inicio de la ventana de tiempo
  pipeline.hsetnx(key, "firstAt", ctx.now.toString());
  // HINCRBY para contar reportes y respuestas del formulario
  pipeline.hincrby(key, "count", 1);
  pipeline.hincrby(key, "formWeapon", flags.weapon ? 1 : 0);
  pipeline.hincrby(key, "formInjured", flags.injured ? 1 : 0);
  pipeline.hincrby(key, "formStillHere", flags.stillHere ? 1 : 0);
  // TTL solo en el primer reporte (NX = solo si no existe) esperar 20 minutos para que expire el conteo y evitar acumulaciones indefinidas
  pipeline.expire(key, WINDOW_20_MIN_SECONDS, "NX");
  // HGET para obtener el timestamp del primer reporte y calcular el tiempo transcurrido desde entonces, para aplicar reglas de tiempo en la decisión de umbral
  pipeline.hget(key, "firstAt");

  const results = await pipeline.exec();

  if (!results) {
    return { publish: false };
  }

  const count = (results[1]?.[1] ?? 0) as number;
  const formWeapon = (results[2]?.[1] ?? 0) as number;
  const formInjured = (results[3]?.[1] ?? 0) as number;
  const formStillHere = (results[4]?.[1] ?? 0) as number;
  const firstAtRaw = (results[6]?.[1] ?? ctx.now.toString()) as string;
  const firstAt = parseInt(firstAtRaw, 10);
  const elapsed = ctx.now - firstAt;
  const within15min = elapsed < WINDOW_15_MIN_MS;

  if (count === 1) {
    return { publish: false };
  }

  let decision: ThresholdDecision;

  if (count >= 5) {
    decision = { publish: true, severity: Severity.CRITICAL, push: true };
  } else if (count >= 3 && within15min) {
    decision = { publish: true, severity: Severity.MODERATE, push: true };
  } else if (count >= 2 && within15min) {
    decision = { publish: true, severity: Severity.LOW, push: false };
  } else {
    return { publish: false };
  }

  // Escalaciones por respuestas del formulario
  if (formWeapon >= 3) {
    decision.severity = Severity.CRITICAL;
    decision.push = true;
  }

  if (formInjured >= 3) {
    decision.severity = Severity.CRITICAL;
    decision.push = true;
    decision.alertPolice = true;
  }

  if (formStillHere >= 3) {
    decision.extendExpiryMinutes = 30;
  }

  return decision;
}

export function thresholdKey(lat: number, lng: number, type: string): string {
  return `threshold:${bucketCoord(lat)}:${bucketCoord(lng)}:${type}`;
}
