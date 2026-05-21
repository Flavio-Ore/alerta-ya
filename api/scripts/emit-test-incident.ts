/**
 * Dispara un evento incident.new (o incident.updated) vía WebSocket para
 * probar en vivo el panel web. NO crea un incidente nuevo — toma uno existente.
 *
 * Uso:
 *   bun run scripts/emit-test-incident.ts [event]
 *
 * Donde event puede ser "new" (default) o "updated".
 *
 * Flujo:
 *   1. Lee un incidente CRÍTICO ACTIVE al azar de la DB
 *   2. Llama al endpoint dev POST /internal/jobs/emit-incident-event con X-Job-Secret
 *   3. El backend emite eventBus.emit(IncidentEvents.NEW, dto)
 *   4. socket.io broadcast a Lima room → el panel web recibe incident:new
 *   5. useIncidentLiveUpdates invalida queries Y dispara toast destructive
 *
 * Requisitos:
 *   - api/ corriendo (docker-compose up o bun run dev)
 *   - seed-incidents.ts ejecutado al menos una vez
 *   - JOB_SECRET seteado en api/.env
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const API_URL = process.env['API_URL']    ?? 'http://localhost:3000';
const SECRET  = process.env['JOB_SECRET'] ?? 'cambia-esto-por-un-secret-seguro-minimo-32-chars';

async function main(): Promise<void> {
  const event = (process.argv[2] ?? 'new') as 'new' | 'updated';
  if (!['new', 'updated'].includes(event)) {
    console.error('Uso: bun run scripts/emit-test-incident.ts [new|updated]');
    process.exit(1);
  }

  // Buscar incidentes ACTIVE — preferentemente CRÍTICOS para que dispare el toast
  const criticals = await prisma.incident.findMany({
    where:   { status: 'ACTIVE', severity: 'CRITICAL' },
    take:    5,
    orderBy: { createdAt: 'desc' },
  });

  const fallback = criticals.length === 0
    ? await prisma.incident.findMany({ where: { status: 'ACTIVE' }, take: 5, orderBy: { createdAt: 'desc' } })
    : [];

  const pool = criticals.length > 0 ? criticals : fallback;

  if (pool.length === 0) {
    console.error('❌ No hay incidentes ACTIVE en la DB. Corré primero:');
    console.error('   bun run scripts/seed-incidents.ts');
    process.exit(1);
  }

  const incident = pool[Math.floor(Math.random() * pool.length)]!;

  console.log(`📡 Disparando "incident:${event}" para:`);
  console.log(`   ${incident.severity} ${incident.type} en ${incident.district}`);
  console.log(`   id: ${incident.id}\n`);

  const res = await fetch(`${API_URL}/internal/jobs/emit-incident-event`, {
    method:  'POST',
    headers: {
      'Content-Type':  'application/json',
      'X-Job-Secret':  SECRET,
    },
    body: JSON.stringify({ incidentId: incident.id, event }),
  });

  if (!res.ok) {
    console.error(`❌ ${res.status} ${res.statusText}`);
    console.error(await res.text());
    process.exit(1);
  }

  const result = await res.json();
  console.log('✅ Evento emitido:', result);
  console.log('\n👀 Si el panel web está abierto en /dashboard, deberías ver:');
  console.log('   - Un toast destructive (si severity=CRITICAL)');
  console.log('   - La lista de incidentes activos se refresca automáticamente');
}

main()
  .catch((err) => {
    console.error('❌ Error:', err);
    process.exit(1);
  })
  .finally(() => {
    void prisma.$disconnect();
  });
