/**
 * Generador del seed temporal de incidentes (api/data/seed-incidents.json).
 *
 * Uso:
 *   bun run scripts/build-seed-incidents.ts
 *
 * El seed es data SINTÉTICA que simula el histórico que el sistema acumularía en
 * producción. Alimenta la señal TEMPORAL (cuándo) del motor de riesgo; la base
 * ESPACIAL (dónde) sale de DATACRIM (ml/data/processed/zones.json).
 *
 * Por qué se genera en vez de escribirse a mano:
 *   - El motor exige >=5 incidentes por distrito x hora (N_SPARSE en
 *     risk-aggregation.ts) para dar confianza 'high'. Debajo de eso degrada a
 *     score plano. Cubrir 48 distritos x sus horas pico a mano es inviable.
 *   - Muestrear los tiles reales de DATACRIM garantiza coordenadas válidas de
 *     Lima y nombres de distrito que ya casan con el join del artefacto.
 *
 * DETERMINISTA: RNG con semilla fija y fecha base constante. Mismo input →
 * mismo output, para que el archivo generado sea reproducible y committeable.
 *
 * Escribe: api/data/seed-incidents.json
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const API_ROOT = join(import.meta.dir, '..');
const REPO_ROOT = join(API_ROOT, '..');

const DATACRIM_PATH = join(REPO_ROOT, 'ml', 'data', 'processed', 'zones.json');
const OUT_PATH = join(API_ROOT, 'data', 'seed-incidents.json');

const RNG_SEED = 20260715;
/** Fecha base fija (no Date.now(): el output debe ser reproducible). */
const BASE_DATE = new Date(2026, 6, 15); // 15-jul-2026, hora local
const HISTORY_DAYS = 60;

/** Registros por distrito: piso garantizado + bonus proporcional al riesgo DATACRIM. */
const MIN_PER_DISTRICT = 70;
const MAX_BONUS = 60;

interface DatacrimTile {
  lat: number;
  lng: number;
  risk: number;
  district: string;
}

interface SeedRow {
  type: string;
  severity: string;
  district: string;
  lat: number;
  lng: number;
  createdAt: string;
}

/** mulberry32 — PRNG determinista y compacto. */
function makeRng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const rng = makeRng(RNG_SEED);

function pickWeighted<T>(items: readonly T[], weights: readonly number[]): T {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = rng() * total;
  for (let i = 0; i < items.length; i++) {
    r -= weights[i]!;
    if (r <= 0) return items[i]!;
  }
  return items[items.length - 1]!;
}

/**
 * Arquetipos de distrito. Sin esto los 46 distritos comparten la misma curva y
 * TODOS piquean a la misma hora con el mismo tipo — buscar cualquier dirección
 * devuelve la misma respuesta y el mapa se ve fabricado. Cada arquetipo modela
 * un patrón urbano distinto de Lima.
 */
type Archetype = 'NIGHTLIFE' | 'COMMERCIAL' | 'RESIDENTIAL' | 'TRANSIT';

/** Peso relativo por hora 0-23 para cada arquetipo. */
const ARCHETYPE_CURVE: Record<Archetype, readonly number[]> = {
  // Zona de bares/restaurantes: pico tardío que se estira a la madrugada.
  NIGHTLIFE: [13, 12, 9, 5, 2, 2, 2, 3, 4, 4, 4, 4, 4, 4, 5, 5, 6, 7, 9, 11, 13, 15, 15, 14],
  // Comercio denso: pico al cierre + repunte de apertura.
  COMMERCIAL: [5, 4, 3, 2, 2, 3, 6, 10, 11, 9, 8, 8, 8, 8, 8, 9, 10, 12, 14, 14, 12, 9, 7, 6],
  // Residencial: pico al regreso del trabajo, cae de madrugada.
  RESIDENTIAL: [6, 5, 3, 2, 2, 2, 4, 6, 6, 5, 4, 4, 4, 4, 5, 5, 6, 8, 11, 14, 14, 12, 9, 7],
  // Corredor de tránsito: doble pico de hora punta.
  TRANSIT: [4, 3, 2, 2, 2, 4, 8, 14, 15, 10, 6, 5, 6, 6, 6, 7, 9, 14, 15, 11, 8, 6, 5, 4],
};

const ARCHETYPES: readonly Archetype[] = ['NIGHTLIFE', 'COMMERCIAL', 'RESIDENTIAL', 'TRANSIT'];

/** Hash estable del nombre — el arquetipo no puede depender del orden de iteración. */
function hashName(name: string): number {
  let h = 0;
  for (const ch of name) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return h;
}

/**
 * Arquetipos anclados a la realidad de Lima donde se conoce; el resto se reparte
 * de forma estable por hash. RESIDENTIAL es el patrón dominante en Lima, así que
 * es el default del reparto.
 */
const KNOWN_ARCHETYPE: Record<string, Archetype> = {
  MIRAFLORES: 'NIGHTLIFE',
  BARRANCO: 'NIGHTLIFE',
  'SAN ISIDRO': 'COMMERCIAL',
  'LA VICTORIA': 'COMMERCIAL',
  LIMA: 'COMMERCIAL',
  'CERCADO DE LIMA': 'COMMERCIAL',
  'SAN JUAN DE LURIGANCHO': 'RESIDENTIAL',
  COMAS: 'RESIDENTIAL',
  'VILLA EL SALVADOR': 'RESIDENTIAL',
  'JESUS MARIA': 'RESIDENTIAL',
  'PUEBLO LIBRE': 'RESIDENTIAL',
  'SAN BORJA': 'RESIDENTIAL',
  'LOS OLIVOS': 'RESIDENTIAL',
  ATE: 'TRANSIT',
  CALLAO: 'TRANSIT',
  'SAN MARTIN DE PORRES': 'TRANSIT',
};

function archetypeFor(district: string): Archetype {
  const known = KNOWN_ARCHETYPE[district.toUpperCase()];
  if (known) return known;
  const h = hashName(district);
  // Sesgo hacia RESIDENTIAL (patrón dominante), resto repartido.
  return h % 5 === 0 ? ARCHETYPES[h % 4]! : 'RESIDENTIAL';
}

/** Curva del arquetipo + corrimiento leve por distrito (evita clones exactos). */
function districtHourCurve(district: string): number[] {
  const base = ARCHETYPE_CURVE[archetypeFor(district)];
  const h = hashName(district);
  const shift = h % 3; // 0-2 horas
  const jitter = 0.9 + ((h >>> 3) % 20) / 100; // 0.90-1.10
  return base.map((_, i) => base[(i - shift + 24) % 24]! * jitter);
}

const TYPES = ['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS'] as const;

/**
 * Mezcla de tipos según arquetipo y franja horaria — hace que topType por hora
 * sea informativo en vez de ROBBERY en todos lados.
 */
function typeWeightsFor(hour: number, arch: Archetype): number[] {
  const night = hour >= 20 || hour <= 3;
  const rush = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
  //                                ROBBERY ACCIDENT HARASSMENT EXTORTION SUSPICIOUS
  if (arch === 'TRANSIT' && rush) return [20, 52, 10, 8, 10];
  if (arch === 'NIGHTLIFE' && night) return [30, 10, 44, 6, 10];
  if (arch === 'COMMERCIAL' && !night) return [30, 12, 12, 38, 8];
  if (night) return [52, 6, 12, 21, 9];
  if (rush) return [28, 38, 15, 11, 8];
  return [34, 16, 24, 14, 12];
}

const SEVERITIES = ['LOW', 'MODERATE', 'CRITICAL'] as const;

/** Severidad sesgada por el riesgo espacial del tile: zona peor → más crítico. */
function severityWeightsFor(risk: number): number[] {
  if (risk >= 67) return [20, 38, 42];
  if (risk >= 34) return [32, 42, 26];
  return [46, 38, 16];
}

function pad(n: number): string {
  return String(n).padStart(2, '0');
}

/** ISO local-naive ("2026-06-24T23:43:33"), igual que el seed previo: el motor
 *  deriva la hora con new Date(...).getHours(), que interpreta hora local. Un
 *  sufijo Z desplazaría la hora por timezone y corrompería la señal temporal. */
function isoLocal(d: Date): string {
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` +
    `T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  );
}

const tiles = JSON.parse(readFileSync(DATACRIM_PATH, 'utf-8')) as DatacrimTile[];

// Agrupa tiles por distrito para muestrear coordenadas reales dentro de cada uno.
const byDistrict = new Map<string, DatacrimTile[]>();
for (const t of tiles) {
  const list = byDistrict.get(t.district);
  if (list) list.push(t);
  else byDistrict.set(t.district, [t]);
}

const rows: SeedRow[] = [];

// Orden estable: sin esto el output dependería del orden de iteración del Map.
const districts = [...byDistrict.keys()].sort();

for (const district of districts) {
  const dTiles = byDistrict.get(district)!;
  const meanRisk = dTiles.reduce((a, t) => a + t.risk, 0) / dTiles.length;

  // Volumen proporcional al riesgo: SJL acumula mucho más que San Isidro.
  const total = MIN_PER_DISTRICT + Math.round((meanRisk / 100) * MAX_BONUS);
  const arch = archetypeFor(district);
  const curve = districtHourCurve(district);

  // Los conteos por hora se ASIGNAN proporcional a la curva, no se samplean.
  // Samplear introduce ruido de Poisson (sigma ~= sqrt(media)) que con ~5
  // incidentes/hora hace que una hora muerta (4am) supere por azar a la hora
  // pico real y produzca un badHours incoherente. La asignación fija la señal.
  const curveSum = curve.reduce((a, b) => a + b, 0);
  const perHour = curve.map((w) => Math.round((total * w) / curveSum));

  for (let hour = 0; hour < 24; hour++) {
    const n = perHour[hour]!;
    if (n === 0) continue;

    // Los tipos también se ASIGNAN, no se samplean: con ~10 incidentes por hora
    // el argmax que calcula topType lo gana cualquier tipo por azar, y el motor
    // reporta HARASSMENT donde el arquetipo dice ROBBERY. Asignar fija la señal.
    const tw = typeWeightsFor(hour, arch);
    const twSum = tw.reduce((a, b) => a + b, 0);
    const hourTypes: string[] = [];
    for (let t = 0; t < TYPES.length; t++) {
      const k = Math.round((n * tw[t]!) / twSum);
      for (let j = 0; j < k; j++) hourTypes.push(TYPES[t]!);
    }
    // El redondeo puede desviarse de n: recorta o rellena con el tipo dominante.
    const dominant = TYPES[tw.indexOf(Math.max(...tw))]!;
    while (hourTypes.length > n) hourTypes.pop();
    while (hourTypes.length < n) hourTypes.push(dominant);

    for (let i = 0; i < n; i++) {
      // Tile ponderado por riesgo: los incidentes caen más en las zonas peores.
      const tile = pickWeighted(dTiles, dTiles.map((t) => t.risk + 1));

      const dayOffset = Math.floor(rng() * HISTORY_DAYS);
      const d = new Date(BASE_DATE);
      d.setDate(d.getDate() - dayOffset);
      d.setHours(hour, Math.floor(rng() * 60), Math.floor(rng() * 60), 0);

      // Dispersión sub-tile (~±250m) para que no queden todos en el centro exacto.
      const jLat = (rng() - 0.5) * 0.005;
      const jLng = (rng() - 0.5) * 0.005;

      rows.push({
        type: hourTypes[i]!,
        severity: pickWeighted(SEVERITIES, severityWeightsFor(tile.risk)),
        district,
        lat: Math.round((tile.lat + jLat) * 1e6) / 1e6,
        lng: Math.round((tile.lng + jLng) * 1e6) / 1e6,
        createdAt: isoLocal(d),
      });
    }
  }
}

// Orden estable por fecha (determinista, desempata por índice implícito).
rows.sort((a, b) => a.createdAt.localeCompare(b.createdAt));

writeFileSync(OUT_PATH, `${JSON.stringify(rows, null, 2)}\n`, 'utf-8');

console.log(
  `[seed-incidents] ${rows.length} registros en ${districts.length} distritos → ${OUT_PATH}`,
);
