import { PrismaClient, IncidentType, Severity, IncidentStatus } from '@prisma/client';

export interface StatsQuery {
  period: 'today' | 'yesterday' | '7d' | '30d' | '12m' | 'all';
  district?: string;
  type?: IncidentType;
  from?: string;
  to?: string;
}

export interface StatsResponse {
  summary: {
    totalIncidents: number;
    activeIncidents: number;
    inAttentionIncidents: number;
    closedIncidents: number;
    criticalIncidents: number;
    totalReports: number;
    totalPanicSessions: number;
    avgConfirmations: number;
    kpis: {
      totalReportes: number;
      completeFormPct: number;
      criticalPct: number;
      aiAccuracyPct: number;
      avgResponseMin: number;
      trend: number;
    };
  };
  byType: { type: IncidentType; count: number }[];
  bySeverity: { severity: Severity; count: number }[];
  byStatus: { status: IncidentStatus; count: number }[];
  byDistrict: { district: string; count: number }[];
  byDay: { date: string; count: number }[];
  byHour: { hour: number; count: number }[];
  byDayHour: { day: number; hour: number; count: number }[];
  byTypeAndSeverity: { type: IncidentType; severity: Severity; count: number }[];
  formAnalysis: {
    weaponType: { label: string; count: number; pct: number }[];
    escapeMethod: { label: string; count: number; pct: number }[];
    stillInZonePct: number;
    avgResponseMin: number;
    topVehicleDistrict: string | null;
  };
  comparison: { current: number; previous: number; percentChange: number } | null;
}

function computeDateRange(query: StatsQuery): { since: Date; until: Date; previousSince: Date } {
  const now = new Date();
  const until = query.to ? new Date(query.to) : now;
  let since: Date;
  let previousSince: Date;

  switch (query.period) {
    case 'today': {
      since = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      previousSince = new Date(since.getTime() - 86_400_000);
      break;
    }
    case 'yesterday': {
      since = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
      previousSince = new Date(since.getTime() - 86_400_000);
      break;
    }
    case '7d': {
      since = new Date(now.getTime() - 7 * 86_400_000);
      previousSince = new Date(since.getTime() - 7 * 86_400_000);
      break;
    }
    case '30d': {
      since = new Date(now.getTime() - 30 * 86_400_000);
      previousSince = new Date(since.getTime() - 30 * 86_400_000);
      break;
    }
    case '12m': {
      since = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
      previousSince = new Date(since.getFullYear() - 1, since.getMonth(), since.getDate());
      break;
    }
    case 'all': {
      since = new Date(0);
      previousSince = new Date(0);
      break;
    }
    default: {
      since = new Date(now.getTime() - 30 * 86_400_000);
      previousSince = new Date(since.getTime() - 30 * 86_400_000);
    }
  }

  if (query.from) since = new Date(query.from);

  return { since, until, previousSince };
}

function buildWhere(query: StatsQuery, since: Date, until: Date): Record<string, unknown> {
  const where: Record<string, unknown> = {
    createdAt: { gte: since, lte: until },
  };
  if (query.district) where.district = query.district;
  if (query.type) where.type = query.type;
  return where;
}

export async function getStats(query: StatsQuery, prisma: PrismaClient): Promise<StatsResponse> {
  const { since, until, previousSince } = computeDateRange(query);
  const where = buildWhere(query, since, until);
  const previousWhere = buildWhere(query, previousSince, since);

  const [
    summary,
    byType,
    bySeverity,
    byStatus,
    byDistrict,
    dayHourData,
    byTypeAndSeverity,
    totalReports,
    totalPanicSessions,
    previousTotal,
    avgResult,
    byDayHourRaw,
    reportsForForm,
    responseTimeIncidents,
    aiReports,
  ] = await Promise.all([
    prisma.incident.aggregate({ where, _count: true }),
    prisma.incident.groupBy({ by: ['type'], where, _count: { id: true }, orderBy: { _count: { id: 'desc' } } }),
    prisma.incident.groupBy({ by: ['severity'], where, _count: { id: true }, orderBy: { _count: { id: 'desc' } } }),
    prisma.incident.groupBy({ by: ['status'], where, _count: { id: true }, orderBy: { _count: { id: 'desc' } } }),
    prisma.incident.groupBy({ by: ['district'], where, _count: { id: true }, orderBy: { _count: { id: 'desc' } } }),
    prisma.incident.findMany({ where, select: { createdAt: true } }).then((rows) => {
      const dayMap = new Map<string, number>();
      const hourMap = new Map<number, number>();
      for (const r of rows) {
        const d = r.createdAt.toISOString().slice(0, 10);
        dayMap.set(d, (dayMap.get(d) ?? 0) + 1);
        const h = r.createdAt.getUTCHours();
        hourMap.set(h, (hourMap.get(h) ?? 0) + 1);
      }
      return {
        byDay: Array.from(dayMap.entries()).sort(([a], [b]) => a.localeCompare(b)).map(([date, count]) => ({ date, count })),
        byHour: Array.from(hourMap.entries()).sort(([a], [b]) => a - b).map(([hour, count]) => ({ hour, count })),
      };
    }),
    prisma.incident.groupBy({ by: ['type', 'severity'], where, _count: { id: true }, orderBy: [{ type: 'asc' }, { severity: 'asc' }] }),
    prisma.report.count({ where: { createdAt: { gte: since, lte: until } } }),
    prisma.panicSession.count({ where: { startedAt: { gte: since, lte: until } } }),
    prisma.incident.count({ where: previousWhere }),
    prisma.incident.aggregate({ where: { ...where, status: { not: 'ACTIVE' } }, _avg: { confirmCount: true } }),
    // byDayHour — día de semana × hora
    prisma.incident.findMany({ where, select: { createdAt: true } }).then((rows) => {
      const map = new Map<string, number>();
      for (const r of rows) {
        const day = r.createdAt.getUTCDay();
        const hour = r.createdAt.getUTCHours();
        const key = `${day}:${hour}`;
        map.set(key, (map.get(key) ?? 0) + 1);
      }
      return Array.from(map.entries()).sort().map(([k, count]) => {
        const [day, hour] = k.split(':').map(Number);
        return { day, hour, count };
      });
    }),
    // formAnalysis — obtener reports con formData en el período
    prisma.report.findMany({
      where: {
        createdAt: { gte: since, lte: until },
        incidentId: { not: null },
      },
      select: {
        formData: true,
        incident: { select: { type: true, district: true } },
      },
    }),
    // avgResponseMin — incidentes no activos para calcular diff
    prisma.incident.findMany({
      where: { ...where, status: { not: 'ACTIVE' } },
      select: { createdAt: true, updatedAt: true },
    }),
    // aiAccuracy — reports con verificación IA
    prisma.report.aggregate({
      where: { createdAt: { gte: since, lte: until }, aiVerified: { not: null } },
      _count: true,
      _avg: { aiScore: true },
    }),
  ]);

  const activeIncidents = byStatus.find((s) => s.status === 'ACTIVE')?._count.id ?? 0;
  const inAttentionIncidents = byStatus.find((s) => s.status === 'IN_ATTENTION')?._count.id ?? 0;
  const closedIncidents = byStatus.find((s) => s.status === 'CLOSED')?._count.id ?? 0;
  const criticalCount = bySeverity.find((s) => s.severity === 'CRITICAL')?._count.id ?? 0;

  const currentPeriodTotal = summary._count;
  const percentChange = previousTotal > 0
    ? Math.round(((currentPeriodTotal - previousTotal) / previousTotal) * 100)
    : currentPeriodTotal > 0 ? 100 : 0;

  // ── formAnalysis ─────────────────────────────────────────────
  const weaponCounts: Record<string, number> = { firearm: 0, blade: 0, none: 0, unknown: 0 };
  const escapeCounts: Record<string, number> = { fled_foot: 0, fled_vehicle: 0, unknown: 0 };
  let stillInZone = 0;
  let totalWithStill = 0;
  const vehicleDistricts: Record<string, number> = {};

  for (const r of reportsForForm) {
    const fd = r.formData as Record<string, string> | null;
    if (!fd) continue;

    // Weapon (solo ROBBERY)
    if (r.incident?.type === 'ROBBERY' && fd.weapon) {
      weaponCounts[fd.weapon] = (weaponCounts[fd.weapon] ?? 0) + 1;
    }

    // Escape method
    if (fd.stillInArea) {
      if (fd.stillInArea === 'fled_foot') escapeCounts.fled_foot++;
      else if (fd.stillInArea === 'fled_vehicle') {
        escapeCounts.fled_vehicle++;
        if (r.incident?.district) {
          vehicleDistricts[r.incident.district] = (vehicleDistricts[r.incident.district] ?? 0) + 1;
        }
      }
      else escapeCounts.unknown++;
    }

    // Still in zone
    if (fd.stillInArea) {
      totalWithStill++;
      if (fd.stillInArea === 'yes') stillInZone++;
    }
  }

  const totalWeapons = Object.values(weaponCounts).reduce((a, b) => a + b, 0);
  const weaponPct = (count: number) => totalWeapons > 0 ? Math.round((count / totalWeapons) * 100) : 0;
  const weaponTypeMap: Record<string, string> = {
    firearm: 'Arma de fuego',
    blade: 'Arma blanca',
    none: 'Sin arma',
    unknown: 'Sin arma',
  };
  const weaponLabels = ['firearm', 'blade', 'none'];
  const weaponTypes = weaponLabels.map((k) => ({
    label: weaponTypeMap[k],
    count: weaponCounts[k] ?? 0,
    pct: weaponPct(weaponCounts[k] ?? 0),
  }));

  const totalEscape = Object.values(escapeCounts).reduce((a, b) => a + b, 0);
  const escapePct = (count: number) => totalEscape > 0 ? Math.round((count / totalEscape) * 100) : 0;
  const escapeMethod = [
    { label: 'A pie', count: escapeCounts.fled_foot, pct: escapePct(escapeCounts.fled_foot) },
    { label: 'Vehículo', count: escapeCounts.fled_vehicle, pct: escapePct(escapeCounts.fled_vehicle) },
    { label: 'No registrado', count: escapeCounts.unknown, pct: escapePct(escapeCounts.unknown) },
  ];

  const stillInZonePct = totalWithStill > 0 ? Math.round((stillInZone / totalWithStill) * 100) : 0;

  const topVehicleDistrict = Object.entries(vehicleDistricts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;

  // ── avgResponseMin ────────────────────────────────────────────
  let avgResponseMin = 0;
  if (responseTimeIncidents.length > 0) {
    const totalMs = responseTimeIncidents.reduce((acc, inc) => {
      return acc + (inc.updatedAt.getTime() - inc.createdAt.getTime());
    }, 0);
    avgResponseMin = Math.round((totalMs / responseTimeIncidents.length / 60000) * 10) / 10;
  }

  // ── aiAccuracy ────────────────────────────────────────────────
  const aiAccuracyPct = aiReports._count > 0
    ? Math.round((aiReports._avg.aiScore ?? 0) * 100)
    : 0;

  // ── completeFormPct — reports que tienen al menos 3 campos en formData ──
  const completeForms = reportsForForm.filter((r) => {
    const fd = r.formData as Record<string, unknown> | null;
    if (!fd) return false;
    return Object.keys(fd).length >= 3;
  });
  const completeFormPct = reportsForForm.length > 0
    ? Math.round((completeForms.length / reportsForForm.length) * 100)
    : 0;

  const criticalPct = currentPeriodTotal > 0
    ? Math.round((criticalCount / currentPeriodTotal) * 100)
    : 0;

  return {
    summary: {
      totalIncidents: currentPeriodTotal,
      activeIncidents,
      inAttentionIncidents,
      closedIncidents,
      criticalIncidents: criticalCount,
      totalReports,
      totalPanicSessions,
      avgConfirmations: Math.round((avgResult._avg.confirmCount ?? 0) * 10) / 10,
      kpis: {
        totalReportes: currentPeriodTotal,
        completeFormPct,
        criticalPct,
        aiAccuracyPct,
        avgResponseMin,
        trend: percentChange,
      },
    },
    byType: byType.map((t) => ({ type: t.type, count: t._count.id })),
    bySeverity: bySeverity.map((s) => ({ severity: s.severity, count: s._count.id })),
    byStatus: byStatus.map((s) => ({ status: s.status, count: s._count.id })),
    byDistrict: byDistrict.map((d) => ({ district: d.district, count: d._count.id })),
    byDay: dayHourData.byDay,
    byHour: dayHourData.byHour,
    byDayHour: byDayHourRaw,
    byTypeAndSeverity: byTypeAndSeverity.map((ts) => ({ type: ts.type, severity: ts.severity, count: ts._count.id })),
    formAnalysis: {
      weaponType: weaponTypes,
      escapeMethod,
      stillInZonePct,
      avgResponseMin,
      topVehicleDistrict,
    },
    comparison: {
      current: currentPeriodTotal,
      previous: previousTotal,
      percentChange,
    },
  };
}
