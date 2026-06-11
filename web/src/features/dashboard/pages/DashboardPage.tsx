import { useMemo } from 'react';
import { useNavigate } from '@tanstack/react-router';

import { useIncidentsList } from '../../incidents/infrastructure/incidents.api';
import { useIncidentLiveUpdates } from '../../incidents/infrastructure/incidents.socket';
import {
  incidentTypeLabel,
  severityLabel,
  formatRelativeTime,
} from '../../incidents/presentation/utils/labels';
import { IncidentsMap } from '../components/IncidentsMap';
import type { PublicIncidentDTO, Severity } from '../../../core/api/types';

const SEVERITY_BAR: Record<Severity, string> = {
  CRITICAL: 'border-stitch-error',
  MODERATE: 'border-stitch-tertiary',
  LOW:      'border-green-500',
};

const SEVERITY_BADGE: Record<Severity, string> = {
  CRITICAL: 'bg-stitch-error/10 text-stitch-error border-stitch-error/20',
  MODERATE: 'bg-stitch-tertiary/10 text-stitch-tertiary border-stitch-tertiary/20',
  LOW:      'bg-green-500/10 text-green-400 border-green-500/20',
};

function IncidentCard({ incident, onClick }: { incident: PublicIncidentDTO; onClick: () => void }) {
  return (
    <article
      className={`bg-stitch-surface-container-low rounded-xl overflow-hidden border-l-4 ${SEVERITY_BAR[incident.severity]} flex flex-col p-4 gap-3`}
    >
      <div className="flex justify-between items-start">
        <div>
          <h3 className="text-sm font-bold text-white">
            {incidentTypeLabel[incident.type]}
          </h3>
          <p className="text-[10px] font-bold text-stitch-on-surface-variant font-label uppercase">
            {formatRelativeTime(incident.createdAt)} · {incident.district}
          </p>
        </div>
        <span
          className={`text-[10px] font-bold px-2 py-0.5 rounded border ${SEVERITY_BADGE[incident.severity]}`}
        >
          {severityLabel[incident.severity].toUpperCase()}
        </span>
      </div>

      <div className="flex items-center justify-between text-[11px] text-stitch-on-surface-variant">
        <span>{incident.reportCount} reportes · {incident.confirmCount} confirman</span>
      </div>

      <button
        onClick={onClick}
        className="w-full bg-stitch-primary-container text-stitch-on-primary-container font-bold py-2 rounded-lg text-xs hover:bg-stitch-primary-container/80 transition-all uppercase tracking-wide font-label"
      >
        Ver detalle
      </button>
    </article>
  );
}

function StatCard({
  label,
  value,
  unit,
  valueClass,
  badge,
}: {
  label:      string;
  value:      string | number;
  unit:       string;
  valueClass: string;
  badge?:     string;
}) {
  return (
    <div className="bg-stitch-surface-container-low p-5 rounded-xl relative">
      <p className="text-[10px] font-bold text-stitch-on-surface-variant uppercase tracking-widest font-label mb-1">
        {label}
      </p>
      <div className="flex items-baseline gap-2">
        <span className={`text-3xl font-headline font-bold ${valueClass}`}>{value}</span>
        <span className="text-xs text-stitch-on-surface-variant">{unit}</span>
      </div>
      {badge && (
        <span className="absolute top-3 right-3 text-[8px] font-bold uppercase tracking-widest text-stitch-tertiary bg-stitch-tertiary/10 px-2 py-0.5 rounded">
          {badge}
        </span>
      )}
    </div>
  );
}

export default function DashboardPage() {
  const navigate = useNavigate();
  useIncidentLiveUpdates();
  // status:'ALL' → trae histórico completo. El KPI "Total" + agregaciones
  // requieren ver TODO (no solo ACTIVE), aunque mapa y lista filtran cliente-side por ACTIVE.
  const { data, isLoading } = useIncidentsList({ pageSize: 100, status: 'ALL' });

  // KPIs según HU008 H8-4: total, críticos, zonas activas
  const stats = useMemo(() => {
    const items = data?.items ?? [];

    const total      = data?.total ?? 0;
    const critical   = items.filter((i) => i.severity === 'CRITICAL').length;
    const activeNow  = items.filter((i) => i.status === 'ACTIVE').length;
    const activeZones = new Set(
      items.filter((i) => i.status === 'ACTIVE').map((i) => i.district),
    ).size;

    return { total, critical, activeNow, activeZones };
  }, [data]);

  const activeIncidents = useMemo(() => {
    const items = (data?.items ?? []).filter((i) => i.status === 'ACTIVE');
    const sevOrder: Record<Severity, number> = { CRITICAL: 0, MODERATE: 1, LOW: 2 };
    return [...items].sort((a, b) => {
      const bySev = sevOrder[a.severity] - sevOrder[b.severity];
      if (bySev !== 0) return bySev;
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });
  }, [data]);

  return (
    <div className="flex-1 p-6 overflow-hidden flex flex-col gap-6">
      {/* Stat Cards Row — HU008 H8-4: total, críticos, zonas activas */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          label="Total"
          value={isLoading ? '—' : stats.total}
          unit="incidentes"
          valueClass="text-white"
        />
        <StatCard
          label="Críticos"
          value={isLoading ? '—' : stats.critical}
          unit="emergencias"
          valueClass="text-stitch-error"
        />
        <StatCard
          label="Zonas activas"
          value={isLoading ? '—' : stats.activeZones}
          unit="distritos"
          valueClass="text-stitch-tertiary"
        />
        <StatCard
          label="Activos ahora"
          value={isLoading ? '—' : stats.activeNow}
          unit="alertas"
          valueClass="text-green-500"
        />
      </div>

      {/* Split: Mapa 65% + Lista 35% */}
      <div className="flex-1 flex gap-6 min-h-0">
        {/* Map */}
        <section className="w-[65%] bg-stitch-surface-container-low rounded-xl relative overflow-hidden flex flex-col">
          <div className="absolute inset-0">
            <IncidentsMap
              incidents={activeIncidents}
              onPinClick={(id) =>
                navigate({ to: '/incidents/$incidentId', params: { incidentId: id } })
              }
            />
          </div>

          {/* Legend */}
          <div className="absolute bottom-4 left-4 bg-stitch-surface/90 backdrop-blur-md p-3 rounded-lg flex flex-col gap-2 z-[1000]">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-stitch-error" />
              <span className="text-[10px] font-bold text-stitch-on-surface font-label uppercase">
                Prioridad Alta
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-stitch-tertiary" />
              <span className="text-[10px] font-bold text-stitch-on-surface font-label uppercase">
                Moderado
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-green-500" />
              <span className="text-[10px] font-bold text-stitch-on-surface font-label uppercase">
                Baja/Informativo
              </span>
            </div>
          </div>
        </section>

        {/* Incident List */}
        <section className="w-[35%] flex flex-col gap-4 min-h-0">
          <div className="flex justify-between items-center">
            <h2 className="text-xs font-black font-label text-stitch-on-surface-variant uppercase tracking-[0.15em]">
              Incidentes Activos
            </h2>
            <span className="text-[10px] text-stitch-on-surface-variant uppercase tracking-widest">
              Ordenar por: Severidad
            </span>
          </div>

          <div className="flex-1 overflow-y-auto space-y-3 pr-2 custom-scrollbar">
            {isLoading && (
              <div className="text-center text-stitch-on-surface-variant py-8 text-xs">
                Cargando incidentes…
              </div>
            )}

            {!isLoading && activeIncidents.length === 0 && (
              <div className="text-center text-stitch-on-surface-variant py-8 text-xs">
                No hay incidentes activos en este momento.
              </div>
            )}

            {activeIncidents.map((inc) => (
              <IncidentCard
                key={inc.id}
                incident={inc}
                onClick={() =>
                  navigate({ to: '/incidents/$incidentId', params: { incidentId: inc.id } })
                }
              />
            ))}
          </div>

          <footer className="flex items-center justify-center gap-2 py-3">
            <span className="material-symbols-outlined text-xs text-stitch-on-surface-variant">
              lock
            </span>
            <span className="text-[10px] font-bold text-stitch-on-surface-variant font-label uppercase tracking-widest">
              Identidad de reportantes: Anónima
            </span>
          </footer>
        </section>
      </div>
    </div>
  );
}
