import { PrismaClient, IncidentType, Severity, IncidentStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  if (process.env['NODE_ENV'] === 'production') {
    console.error('Seed no debe correr en producción');
    process.exit(1);
  }

  console.log('Sembrando datos de prueba para Lima...');

  const user = await prisma.user.upsert({
    where: { firebaseUid: 'seed-user-001' },
    update: {},
    create: {
      firebaseUid: 'seed-user-001',
      reputationScore: 100,
    },
  });

  await prisma.incident.upsert({
    where: { id: 'seed-incident-001' },
    update: { aiScore: 0.88, aiVerified: true },
    create: {
      id: 'seed-incident-001',
      type: IncidentType.ROBBERY,
      severity: Severity.MODERATE,
      status: IncidentStatus.ACTIVE,
      lat: -12.1167,
      lng: -77.0372,
      district: 'Miraflores',
      confirmCount: 2,
      denyCount: 0,
      reportCount: 3,
      expiresAt: new Date(Date.now() + 20 * 60 * 1000),
      aiScore: 0.88,        // verificado por IA
      aiVerified: true,
    },
  });

  await prisma.incident.upsert({
    where: { id: 'seed-incident-002' },
    update: { aiScore: 0.34, aiVerified: false },
    create: {
      id: 'seed-incident-002',
      type: IncidentType.ACCIDENT,
      severity: Severity.LOW,
      status: IncidentStatus.ACTIVE,
      lat: -12.0853,
      lng: -77.0508,
      district: 'San Isidro',
      confirmCount: 1,
      denyCount: 0,
      reportCount: 2,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
      aiScore: 0.34,        // marcado como sospechoso por IA
      aiVerified: false,
    },
  });

  // Zonas de riesgo — incluye zona demo de la universidad (Av. El Sol 235, SJL)
  await prisma.riskZone.upsert({
    where: { id: 'seed-risk-001' },
    update: {},
    create: {
      id: 'seed-risk-001',
      district: 'La Victoria',
      lat: -12.0656,
      lng: -77.0136,
      riskScore: 72,
      predictedHour: 22,
    },
  });

  // Zona roja demo — Av. El Sol 235, San Juan de Lurigancho (universidad)
  await prisma.riskZone.upsert({
    where: { id: 'seed-risk-demo' },
    update: { riskScore: 88, predictedHour: 13 },
    create: {
      id: 'seed-risk-demo',
      district: 'San Juan de Lurigancho',
      lat: -11.9800,
      lng: -77.0050,
      riskScore: 88,
      predictedHour: 13, // hora pico: mediodía (salida de clases)
    },
  });

  // Incidente CRITICAL pre-cargado en la zona de la universidad para la demo
  await prisma.incident.upsert({
    where: { id: 'seed-incident-demo' },
    update: { aiScore: 0.79, aiVerified: true },
    create: {
      id: 'seed-incident-demo',
      type: IncidentType.ROBBERY,
      severity: Severity.CRITICAL,
      status: IncidentStatus.ACTIVE,
      lat: -11.9800,
      lng: -77.0050,
      district: 'San Juan de Lurigancho',
      confirmCount: 4,
      denyCount: 0,
      reportCount: 5,
      expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hora
      aiScore: 0.79,        // verificado por IA (alta confianza)
      aiVerified: true,
    },
  });

  // Reporte de prueba (nunca exponer el userId en respuestas)
  await prisma.report.upsert({
    where: { id: 'seed-report-001' },
    update: {},
    create: {
      id: 'seed-report-001',
      userId: user.id,
      incidentId: 'seed-incident-001',
      lat: -12.1167,
      lng: -77.0372,
      formData: { personsInvolved: '2-3', weapon: true, stillInArea: false, fleeDirection: 'north' },
      mediaUrls: [],
    },
  });

  console.log('Seed completado.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
