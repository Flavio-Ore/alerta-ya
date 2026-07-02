import { AppError } from '../../../../core/errors/AppError';
import { isWithinLima, getDistrict } from '../../../../core/utils/geo.utils';
import { RiskArtifact, RiskLevel, Confidence, normalizeDistrict, DatacrimTile } from '../risk-aggregation';

export interface NearbyTile {
  lat: number;
  lng: number;
  risk: number;
}

export interface RiskDTO {
  district: string;
  hour: number;
  riskScore: number | null; // null si no hay datos (fail-open)
  level: RiskLevel | 'unknown';
  topType: string | null;
  confidence: Confidence | 'none';
  badHours: number[];
  nearbyTiles: NearbyTile[];
}

const NEARBY_LIMIT = 40;

function distanceSq(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const dLat = aLat - bLat;
  const dLng = aLng - bLng;
  return dLat * dLat + dLng * dLng;
}

/** Tiles más cercanos al punto, para el heatmap del mapa. */
function nearbyTiles(tiles: DatacrimTile[], lat: number, lng: number): NearbyTile[] {
  return [...tiles]
    .sort((a, b) => distanceSq(a.lat, a.lng, lat, lng) - distanceSq(b.lat, b.lng, lat, lng))
    .slice(0, NEARBY_LIMIT)
    .map((t) => ({ lat: t.lat, lng: t.lng, risk: t.risk }));
}

function nearestTileDistrict(tiles: DatacrimTile[], lat: number, lng: number): string | null {
  let best: DatacrimTile | null = null;
  let bestD = Infinity;
  for (const t of tiles) {
    const d = distanceSq(t.lat, t.lng, lat, lng);
    if (d < bestD) {
      bestD = d;
      best = t;
    }
  }
  return best ? normalizeDistrict(best.district) : null;
}

/**
 * Riesgo de un punto a una hora dada. 422 fuera de Lima. Fail-open: sin artefacto
 * o sin datos del distrito → respuesta 'unknown' con score null (nunca crashea/blank).
 * Todo es agregado ANÓNIMO — nunca expone reportes individuales ni identidad.
 */
export function getRisk(
  lat: number,
  lng: number,
  hour: number,
  artifact: RiskArtifact | null,
): RiskDTO {
  if (!isWithinLima(lat, lng)) {
    throw new AppError(422, 'Coordenadas fuera del área de Lima Metropolitana');
  }

  const tiles = artifact?.tiles ?? [];
  const nearby = nearbyTiles(tiles, lat, lng);

  // Resuelve el distrito: primero por geo.utils, luego por tile más cercano.
  let key = normalizeDistrict(getDistrict(lat, lng));
  let dr = artifact?.districts[key];
  if (!dr && artifact) {
    const fallback = nearestTileDistrict(tiles, lat, lng);
    if (fallback) {
      key = fallback;
      dr = artifact.districts[key];
    }
  }

  if (!dr) {
    return {
      district: 'Lima Metropolitana',
      hour,
      riskScore: null,
      level: 'unknown',
      topType: null,
      confidence: 'none',
      badHours: [],
      nearbyTiles: nearby,
    };
  }

  const stat = dr.hourly[hour] ?? dr.hourly[0]!;
  return {
    district: dr.displayName,
    hour,
    riskScore: stat.score,
    level: stat.level,
    topType: stat.topType,
    confidence: stat.confidence,
    badHours: dr.badHours,
    nearbyTiles: nearby,
  };
}
