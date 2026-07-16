/**
 * Artefacto de riesgo VIVO: seed simulado + incidentes reales de PostgreSQL.
 *
 * Por qué existe:
 *   El artefacto horneado (risk-artifact.repository) es estático — se calcula en
 *   build time desde el seed y nunca ve un reporte ciudadano. Este módulo suma los
 *   incidentes reales encima, para que la pantalla de riesgo reaccione a lo que
 *   pasa en la app.
 *
 * Por qué SUMA en vez de reemplazar:
 *   El seed es la historia simulada que le da densidad estadística al motor (el
 *   umbral N_SPARSE=5 por distrito×hora). Con la tabla vacía, leer solo de la BD
 *   daría "sin datos" en toda Lima. Sumando, la BD solo puede mejorar la señal.
 *
 * Fail-open (crítico): cualquier fallo de BD cae al artefacto horneado, que viaja
 * en la imagen. La pantalla de riesgo NUNCA depende de que Cloud SQL responda.
 *
 * Invalidación por watermark: cada request compara (count, max(createdAt)) contra
 * lo último calculado. Si nadie reportó, sirve el cache — sin recomputar. Es una
 * query index-only, no un scan.
 */
import { PrismaClient } from '@prisma/client';

import { computeRiskArtifact, RiskArtifact } from '../domain/risk-aggregation';
import { loadSeedIncidents, SeedIncident } from './seed-loader';
import { getRiskArtifact } from './risk-artifact.repository';

/**
 * Perú no aplica horario de verano: siempre UTC-5.
 *
 * El motor deriva la hora con `new Date(createdAt).getHours()`. El seed usa ISO
 * local-naive ("2026-06-24T21:30:00"), que round-trippea bien en cualquier TZ.
 * Pero Prisma devuelve un Date absoluto y Cloud Run corre en UTC: un incidente de
 * las 21:30 de Lima se guarda 02:30Z y getHours() daría 2 — el reporte caería 5
 * horas corrido, en el bucket equivocado, sin que nada falle visiblemente.
 * Por eso convertimos a hora de pared de Lima ANTES de entregárselo al motor.
 */
const LIMA_UTC_OFFSET_HOURS = -5;

/** Date absoluto → ISO local-naive en hora de Lima (misma convención que el seed). */
export function toLimaNaiveIso(d: Date): string {
  const shifted = new Date(d.getTime() + LIMA_UTC_OFFSET_HOURS * 3600_000);
  return shifted.toISOString().slice(0, 19);
}

/**
 * Techo de filas traídas de la BD. La agregación es O(n) sobre los incidentes y
 * el payload crece con la tabla. Si esto se queda corto, el paso siguiente es
 * agregar con GROUP BY en Postgres (district, hora, tipo, severidad) para que el
 * payload deje de depender del volumen — no subir este número.
 */
const MAX_LIVE_INCIDENTS = 50_000;

/** No recalcular más seguido que esto aunque el watermark cambie. */
const MIN_RECOMPUTE_MS = 60_000;

interface Watermark {
  count: number;
  maxAt: number;
}

interface LiveCache extends Watermark {
  artifact: RiskArtifact;
  computedAt: number;
}

let cache: LiveCache | null = null;

/** Solo para tests. */
export function __resetLiveRiskCache(): void {
  cache = null;
}

/** Huella barata del estado de la tabla: si no cambió, no hay nada que recalcular. */
async function readWatermark(prisma: PrismaClient): Promise<Watermark> {
  const r = await prisma.incident.aggregate({
    _count: { _all: true },
    _max: { createdAt: true },
  });
  return { count: r._count._all, maxAt: r._max.createdAt?.getTime() ?? 0 };
}

/**
 * Incidentes reales como señal temporal. Solo se leen los campos que el motor usa
 * (district, createdAt, type, severity) más lat/lng por el contrato de SeedIncident
 * — la base espacial sale de los tiles DATACRIM, no de acá.
 */
export async function loadLiveIncidents(prisma: PrismaClient): Promise<SeedIncident[]> {
  const rows = await prisma.incident.findMany({
    select: { type: true, severity: true, district: true, lat: true, lng: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
    take: MAX_LIVE_INCIDENTS,
  });
  return rows.map((r) => ({
    type: r.type,
    severity: r.severity,
    district: r.district,
    lat: r.lat,
    lng: r.lng,
    createdAt: toLimaNaiveIso(r.createdAt),
  }));
}

/**
 * Artefacto a servir: seed + incidentes reales, cacheado por watermark.
 * Ante cualquier error de BD retorna el artefacto horneado (nunca lanza).
 *
 * Los tiles salen del artefacto horneado, NO de ml/data/processed/zones.json:
 * el build context del Dockerfile es ./api, así que ml/ nunca entra a la imagen y
 * recomputar desde ese archivo lanzaría ENOENT en Cloud Run — el merge degradaría
 * siempre, en silencio. El artefacto ya trae los tiles y computeRiskArtifact los
 * pasa tal cual, así que reusarlos es equivalente y evita releer 800KB de JSON.
 */
export async function getLiveRiskArtifact(prisma: PrismaClient): Promise<RiskArtifact | null> {
  const baked = getRiskArtifact();
  if (!baked) return null; // sin base espacial no hay riesgo que calcular

  try {
    const wm = await readWatermark(prisma);

    if (cache && cache.count === wm.count && cache.maxAt === wm.maxAt) return cache.artifact;
    // Hay data nueva, pero recién recalculamos: servir el cache hasta que pase el TTL.
    if (cache && Date.now() - cache.computedAt < MIN_RECOMPUTE_MS) return cache.artifact;

    const live = await loadLiveIncidents(prisma);

    // Sin incidentes reales el horneado ya es la respuesta correcta — pero igual
    // se cachea: si no, una tabla vacía dispararía findMany en cada request.
    const artifact =
      live.length === 0
        ? baked
        : computeRiskArtifact(baked.tiles, [...loadSeedIncidents(), ...live]);

    cache = { artifact, count: wm.count, maxAt: wm.maxAt, computedAt: Date.now() };
    return artifact;
  } catch (err) {
    console.error('Live risk merge failed, serving baked artifact:', (err as Error).message);
    return baked;
  }
}
