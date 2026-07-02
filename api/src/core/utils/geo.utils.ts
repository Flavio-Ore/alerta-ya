const LIMA_BOUNDS = {
  latMin: -12.28,
  latMax: -11.77,
  lngMin: -77.17,
  lngMax: -76.78,
} as const;

// Bounding boxes aproximados de distritos de Lima para MVP
const DISTRICTS: { name: string; latMin: number; latMax: number; lngMin: number; lngMax: number }[] = [
  { name: 'Miraflores',            latMin: -12.145, latMax: -12.108, lngMin: -77.065, lngMax: -77.030 },
  { name: 'San Isidro',            latMin: -12.110, latMax: -12.085, lngMin: -77.065, lngMax: -77.030 },
  { name: 'Barranco',              latMin: -12.158, latMax: -12.138, lngMin: -77.025, lngMax: -77.000 },
  { name: 'Surco',                 latMin: -12.165, latMax: -12.105, lngMin: -77.015, lngMax: -76.960 },
  { name: 'La Molina',             latMin: -12.110, latMax: -12.060, lngMin: -76.960, lngMax: -76.900 },
  { name: 'San Borja',             latMin: -12.108, latMax: -12.085, lngMin: -77.015, lngMax: -76.990 },
  { name: 'Surquillo',             latMin: -12.125, latMax: -12.105, lngMin: -77.035, lngMax: -77.010 },
  { name: 'San Miguel',            latMin: -12.088, latMax: -12.065, lngMin: -77.110, lngMax: -77.080 },
  { name: 'Magdalena del Mar',     latMin: -12.100, latMax: -12.080, lngMin: -77.080, lngMax: -77.055 },
  { name: 'Jesús María',           latMin: -12.085, latMax: -12.065, lngMin: -77.060, lngMax: -77.035 },
  { name: 'Lince',                 latMin: -12.090, latMax: -12.070, lngMin: -77.045, lngMax: -77.025 },
  { name: 'La Victoria',           latMin: -12.080, latMax: -12.055, lngMin: -77.020, lngMax: -76.995 },
  { name: 'El Agustino',           latMin: -12.065, latMax: -12.035, lngMin: -77.010, lngMax: -76.980 },
  { name: 'Ate',                   latMin: -12.060, latMax: -11.990, lngMin: -76.980, lngMax: -76.880 },
  { name: 'Lima Cercado',          latMin: -12.060, latMax: -12.030, lngMin: -77.055, lngMax: -77.015 },
  { name: 'Breña',                 latMin: -12.060, latMax: -12.045, lngMin: -77.060, lngMax: -77.040 },
  { name: 'Pueblo Libre',          latMin: -12.080, latMax: -12.060, lngMin: -77.080, lngMax: -77.055 },
  { name: 'Rímac',                 latMin: -12.030, latMax: -12.000, lngMin: -77.045, lngMax: -77.010 },
  { name: 'San Juan de Lurigancho',latMin: -12.020, latMax: -11.880, lngMin: -77.020, lngMax: -76.940 },
  { name: 'San Juan de Miraflores',latMin: -12.180, latMax: -12.130, lngMin: -77.020, lngMax: -76.960 },
  { name: 'Villa El Salvador',     latMin: -12.225, latMax: -12.175, lngMin: -76.960, lngMax: -76.915 },
  { name: 'Villa María del Triunfo',latMin: -12.200, latMax: -12.150, lngMin: -77.000, lngMax: -76.940 },
  { name: 'San Martín de Porres',  latMin: -12.010, latMax: -11.960, lngMin: -77.090, lngMax: -77.050 },
  { name: 'Los Olivos',            latMin: -11.970, latMax: -11.920, lngMin: -77.085, lngMax: -77.045 },
  { name: 'Independencia',         latMin: -12.005, latMax: -11.975, lngMin: -77.065, lngMax: -77.030 },
  { name: 'Comas',                 latMin: -11.970, latMax: -11.910, lngMin: -77.075, lngMax: -77.025 },
  { name: 'Callao',                latMin: -12.065, latMax: -12.020, lngMin: -77.165, lngMax: -77.100 },
];

export function isWithinLima(lat: number, lng: number): boolean {
  return (
    lat >= LIMA_BOUNDS.latMin &&
    lat <= LIMA_BOUNDS.latMax &&
    lng >= LIMA_BOUNDS.lngMin &&
    lng <= LIMA_BOUNDS.lngMax
  );
}

export function getDistrict(lat: number, lng: number): string {
  const match = DISTRICTS.find(
    (d) => lat >= d.latMin && lat <= d.latMax && lng >= d.lngMin && lng <= d.lngMax,
  );
  return match?.name ?? 'Lima Metropolitana';
}

// Redondear a 3 decimales (~100m grid) para agrupar reportes cercanos
export function bucketCoord(coord: number): number {
  return Math.round(coord * 1000) / 1000;
}

const EARTH_RADIUS_METERS = 6_371_000;

function toRadians(deg: number): number {
  return (deg * Math.PI) / 180;
}

/** Distancia haversine en metros entre dos coordenadas. */
export function distanceMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_METERS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
