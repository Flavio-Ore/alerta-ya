/**
 * Seed de incidentes para desarrollo local del panel web.
 *
 * Uso:
 *   bun run scripts/seed-incidents.ts
 *
 * Crea ~15 incidentes en distritos reales de Lima con variedad de:
 * - severidad (LOW / MODERATE / CRITICAL)
 * - status (ACTIVE / IN_ATTENTION / CLOSED)
 * - tipo (ROBBERY / ACCIDENT / HARASSMENT / EXTORTION / SUSPICIOUS)
 * - timestamps (algunos hoy, otros días atrás)
 *
 * NOTA: este seed NO ejecuta el threshold engine ni publica vía WebSocket.
 * Es solo data inerte para que el panel renderice.
 * Para probar WebSocket en vivo, usar scripts/emit-test-incident.ts.
 */
import { PrismaClient, IncidentType, Severity, IncidentStatus } from '@prisma/client';

const prisma = new PrismaClient();

const SEED_USER_FIREBASE_UID = 'seed-user-dev';

interface SeedIncident {
  type:     IncidentType;
  severity: Severity;
  status:   IncidentStatus;
  lat:      number;
  lng:      number;
  district: string;
  reportCount:  number;
  confirmCount: number;
  denyCount:    number;
  hoursAgo:     number;
  feedback?:    string;
}

const INCIDENTS: SeedIncident[] = [
  // CRÍTICOS activos — distritos centrales
  { type: 'ROBBERY',    severity: 'CRITICAL', status: 'ACTIVE',       lat: -12.1211, lng: -77.0297, district: 'Miraflores',  reportCount: 8, confirmCount: 6, denyCount: 0, hoursAgo: 0.3 },
  { type: 'EXTORTION',  severity: 'CRITICAL', status: 'ACTIVE',       lat: -12.0976, lng: -77.0365, district: 'San Isidro',  reportCount: 5, confirmCount: 4, denyCount: 1, hoursAgo: 0.6 },
  { type: 'ROBBERY',    severity: 'CRITICAL', status: 'IN_ATTENTION', lat: -12.0463, lng: -77.0427, district: 'Cercado de Lima', reportCount: 12, confirmCount: 10, denyCount: 0, hoursAgo: 1.2, feedback: 'Unidad asignada en camino — Comisaría Cercado.' },

  // MODERADOS — varios
  { type: 'ACCIDENT',   severity: 'MODERATE', status: 'ACTIVE',       lat: -12.1359, lng: -76.9914, district: 'Santiago de Surco',   reportCount: 4, confirmCount: 3, denyCount: 0, hoursAgo: 0.8 },
  { type: 'HARASSMENT', severity: 'MODERATE', status: 'ACTIVE',       lat: -12.1463, lng: -77.0218, district: 'Barranco',     reportCount: 3, confirmCount: 2, denyCount: 1, hoursAgo: 2.1 },
  { type: 'SUSPICIOUS', severity: 'MODERATE', status: 'ACTIVE',       lat: -12.1031, lng: -76.9984, district: 'San Borja',    reportCount: 3, confirmCount: 2, denyCount: 0, hoursAgo: 3.5 },
  { type: 'ACCIDENT',   severity: 'MODERATE', status: 'IN_ATTENTION', lat: -12.0625, lng: -77.1166, district: 'Callao',       reportCount: 6, confirmCount: 4, denyCount: 1, hoursAgo: 4.0 },

  // LOW — informativos
  { type: 'SUSPICIOUS', severity: 'LOW',      status: 'ACTIVE',       lat: -12.0774, lng: -76.9433, district: 'La Molina',    reportCount: 2, confirmCount: 1, denyCount: 0, hoursAgo: 5.0 },
  { type: 'HARASSMENT', severity: 'LOW',      status: 'ACTIVE',       lat: -11.9995, lng: -77.0665, district: 'Los Olivos',   reportCount: 2, confirmCount: 1, denyCount: 0, hoursAgo: 6.5 },

  // Resueltos (historial)
  { type: 'ROBBERY',    severity: 'CRITICAL', status: 'CLOSED', lat: -11.9923, lng: -76.9975, district: 'San Juan de Lurigancho', reportCount: 9, confirmCount: 7, denyCount: 0, hoursAgo: 22, feedback: 'Detenidos por patrullero 12. Caso cerrado.' },
  { type: 'ACCIDENT',   severity: 'MODERATE', status: 'CLOSED', lat: -11.9481, lng: -77.0466, district: 'Comas',        reportCount: 5, confirmCount: 4, denyCount: 0, hoursAgo: 28, feedback: 'Tránsito restaurado.' },
  { type: 'SUSPICIOUS', severity: 'LOW',      status: 'CLOSED', lat: -12.0250, lng: -76.9170, district: 'Ate',          reportCount: 2, confirmCount: 1, denyCount: 1, hoursAgo: 48, feedback: 'Verificado por Serenazgo. Sin novedad.' },

  // Histórico semana pasada
  { type: 'EXTORTION',  severity: 'CRITICAL', status: 'CLOSED', lat: -12.2130, lng: -76.9370, district: 'Villa El Salvador', reportCount: 11, confirmCount: 8, denyCount: 0, hoursAgo: 72, feedback: 'Operativo conjunto. Detenidos.' },
  { type: 'HARASSMENT', severity: 'MODERATE', status: 'CLOSED', lat: -12.1211, lng: -77.0297, district: 'Miraflores',   reportCount: 3, confirmCount: 2, denyCount: 0, hoursAgo: 120 },
  { type: 'ROBBERY',    severity: 'MODERATE', status: 'CLOSED', lat: -12.0976, lng: -77.0365, district: 'San Isidro',   reportCount: 4, confirmCount: 3, denyCount: 0, hoursAgo: 168, feedback: 'Reporte derivado a PNP.' },
];

async function main(): Promise<void> {
  console.log('🌱 Seed de incidentes — AlertaYa\n');

  // 1. User seed (FK requerido por Report)
  const user = await prisma.user.upsert({
    where:  { firebaseUid: SEED_USER_FIREBASE_UID },
    update: {},
    create: { firebaseUid: SEED_USER_FIREBASE_UID, reputationScore: 100 },
  });
  console.log(`✓ User seed: ${user.id}`);

  // 2. Limpiar incidentes previos del seed para evitar duplicados acumulados
  const previousCount = await prisma.incident.count();
  if (previousCount > 0) {
    console.log(`⚠️  Hay ${previousCount} incidentes existentes en DB.`);
    console.log('    El seed AGREGA, no borra. Si querés limpiar, corré:');
    console.log('    bun run prisma:reset    (⚠️ borra TODA la DB)\n');
  }

  // 3. Crear incidentes + 1 report por incidente (para evidencia)
  const now = Date.now();
  let created = 0;

  for (const seed of INCIDENTS) {
    const createdAt = new Date(now - seed.hoursAgo * 60 * 60 * 1000);
    const expiresAt = new Date(createdAt.getTime() + 24 * 60 * 60 * 1000);

    const incident = await prisma.incident.create({
      data: {
        type:         seed.type,
        severity:     seed.severity,
        status:       seed.status,
        lat:          seed.lat,
        lng:          seed.lng,
        district:     seed.district,
        reportCount:  seed.reportCount,
        confirmCount: seed.confirmCount,
        denyCount:    seed.denyCount,
        feedback:     seed.feedback,
        createdAt,
        updatedAt:    createdAt,
        expiresAt,
        reports: {
          create: {
            userId:   user.id,
            lat:      seed.lat,
            lng:      seed.lng,
            formData: {
              involved:        seed.type === 'ROBBERY' ? '2-3 personas' : '1 persona',
              weapon:          seed.type === 'ROBBERY' || seed.type === 'EXTORTION' ? 'arma de fuego' : 'ninguna',
              still_present:   seed.status === 'ACTIVE',
              description:     `Reporte ciudadano automático (seed) — ${seed.type.toLowerCase()} en ${seed.district}.`,
            },
            mediaUrls: [],
            createdAt,
          },
        },
      },
    });

    console.log(`  ✓ ${incident.severity.padEnd(8)} ${incident.type.padEnd(11)} ${incident.district.padEnd(28)} (${seed.hoursAgo}h ago, ${incident.status})`);
    created++;
  }

  console.log(`\n✅ ${created} incidentes creados. Refrescá http://localhost:5173/dashboard para verlos.\n`);
}

main()
  .catch((err) => {
    console.error('❌ Error en seed:', err);
    process.exit(1);
  })
  .finally(() => {
    void prisma.$disconnect();
  });
