import { useMemo, useState } from "react";
import { useNavigate } from "@tanstack/react-router";

import { useIncidentsList } from "../../incidents/infrastructure/incidents.api";
import { useIncidentLiveUpdates } from "../../incidents/infrastructure/incidents.socket";
import { useActivePanicSessions } from "../../panic/infrastructure/panic.api";
import { usePanicLiveUpdates } from "../../panic/infrastructure/panic.socket";
import {
  incidentTypeLabel,
  severityLabel,
  formatRelativeTime,
} from "../../incidents/presentation/utils/labels";
import { IncidentsMap } from "../components/IncidentsMap";
import { AiConfidenceBadge } from "../../../core/components/AiConfidenceBadge";
import type {
  PublicIncidentDTO,
  Severity,
  IncidentType,
} from "../../../core/api/types";
import {
  TYPE_OPTIONS,
  SEVERITY_OPTIONS,
} from "../../../core/components/ui/FilterSelect";

const SEVERITY_BAR: Record<Severity, string> = {
  CRITICAL: "border-stitch-error",
  MODERATE: "border-stitch-tertiary",
  LOW: "border-green-500",
};

const SEVERITY_BADGE: Record<Severity, string> = {
  CRITICAL: "bg-stitch-error/10 text-stitch-error border-stitch-error/20",
  MODERATE:
    "bg-stitch-tertiary/10 text-stitch-tertiary border-stitch-tertiary/20",
  LOW: "bg-green-500/10 text-green-400 border-green-500/20",
};

function IncidentCard({
  incident,
  onClick,
}: {
  incident: PublicIncidentDTO;
  onClick: () => void;
}) {
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
        <div className="flex flex-col items-end gap-1">
          <span
            title="Gravedad, según reportes ciudadanos"
            className={`text-[10px] font-bold px-2 py-0.5 rounded border ${SEVERITY_BADGE[incident.severity]}`}
          >
            {severityLabel[incident.severity].toUpperCase()}
          </span>
          <AiConfidenceBadge
            score={incident.aiScore}
            verified={incident.aiVerified}
          />
        </div>
      </div>

      <div className="flex items-center justify-between text-[11px] text-stitch-on-surface-variant">
        <span>
          {incident.reportCount} reportes · {incident.confirmCount} confirman
        </span>
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
  label: string;
  value: string | number;
  unit: string;
  valueClass: string;
  badge?: string;
}) {
  return (
    <div className="bg-stitch-surface-container-low p-5 rounded-xl relative">
      <p className="text-[10px] font-bold text-stitch-on-surface-variant uppercase tracking-widest font-label mb-1">
        {label}
      </p>
      <div className="flex items-baseline gap-2">
        <span className={`text-3xl font-headline font-bold ${valueClass}`}>
          {value}
        </span>
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

type SortMode = "triage" | "recent" | "confirmed";

const SORT_LABEL: Record<SortMode, string> = {
  triage: "Prioridad",
  recent: "Reciente",
  confirmed: "Confirmado",
};

const SEVERITY_WEIGHT: Record<Severity, number> = {
  CRITICAL: 3,
  MODERATE: 2,
  LOW: 1,
};

/**
 * Activo REAL = status ACTIVE y NO vencido. El job que cierra vencidos corre
 * por Cloud Scheduler (ausente en local), así que el flag `status` por sí solo
 * no es confiable: un ACTIVE con expiresAt pasado está efectivamente vencido.
 */
function isEffectivelyActive(i: PublicIncidentDTO, now: number): boolean {
  return i.status === "ACTIVE" && new Date(i.expiresAt).getTime() > now;
}

/**
 * Score de triage: severidad × frescura × validación social.
 * Lo severo + reciente + confirmado flota arriba; un crítico de 48 días se hunde.
 * recency: decae ~50% por día (1d≈0.5, 2d≈0.33, 48d≈0.02).
 * confirmBoost: hasta +50% si la comunidad confirma.
 */
function triageScore(i: PublicIncidentDTO, now: number): number {
  const hoursOld = (now - new Date(i.createdAt).getTime()) / 3_600_000;
  const recency = 1 / (1 + hoursOld / 24);
  const votes = i.confirmCount + i.denyCount;
  const confirmRatio = votes > 0 ? i.confirmCount / votes : 0;
  return SEVERITY_WEIGHT[i.severity] * recency * (1 + 0.5 * confirmRatio);
}

export default function DashboardPage() {
  const navigate = useNavigate();
  useIncidentLiveUpdates();
  usePanicLiveUpdates();
  const { data: panicData } = useActivePanicSessions();
  const panicSessions = panicData ?? [];
  // status:'ALL' → trae histórico completo. Las métricas filtran cliente-side
  // por status para reflejar SOLO lo que pasa en vivo (no el histórico).
  const { data, isLoading } = useIncidentsList({
    pageSize: 100,
    status: "ALL",
  });

  const [sortMode, setSortMode] = useState<SortMode>("triage");

  // ── Filter state ──────────────────────────────────────────────
  const [typeFilter, setTypeFilter] = useState<IncidentType | "ALL">("ALL");
  const [severityFilter, setSeverityFilter] = useState<Severity | "ALL">("ALL");
  const [districtFilter, setDistrictFilter] = useState("ALL");
  const [searchQuery, setSearchQuery] = useState("");

  const hasActiveFilters =
    typeFilter !== "ALL" ||
    severityFilter !== "ALL" ||
    districtFilter !== "ALL" ||
    searchQuery !== "";



  // Métricas live-scoped: cuentan lo que necesita acción AHORA, no el histórico.
  const stats = useMemo(() => {
    const items = data?.items ?? [];
    const now = Date.now();
    const activeNow = items.filter((i) => isEffectivelyActive(i, now)).length;
    const criticalActive = items.filter(
      (i) => isEffectivelyActive(i, now) && i.severity === "CRITICAL",
    ).length;
    const inAttention = items.filter((i) => i.status === "IN_ATTENTION").length;
    return { activeNow, criticalActive, inAttention };
  }, [data]);

  // Activos reales + filtros (#19) + orden seleccionado (sortMode). Alimenta
  // mapa y lista lateral.
  const filteredIncidents = useMemo(() => {
    const now = Date.now();
    const items = (data?.items ?? []).filter((i) =>
      isEffectivelyActive(i, now),
    );
    const filtered = items.filter((i) => {
      if (typeFilter !== "ALL" && i.type !== typeFilter) return false;
      if (severityFilter !== "ALL" && i.severity !== severityFilter)
        return false;
      if (districtFilter !== "ALL" && i.district !== districtFilter)
        return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matches =
          i.district.toLowerCase().includes(q) ||
          incidentTypeLabel[i.type].toLowerCase().includes(q) ||
          severityLabel[i.severity].toLowerCase().includes(q);
        if (!matches) return false;
      }
      return true;
    });
    const sorted = [...filtered];
    if (sortMode === "recent") {
      sorted.sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
      );
    } else if (sortMode === "confirmed") {
      sorted.sort((a, b) => b.confirmCount - a.confirmCount);
    } else {
      sorted.sort((a, b) => triageScore(b, now) - triageScore(a, now));
    }
    return sorted;
  }, [data, sortMode, typeFilter, severityFilter, districtFilter, searchQuery]);

  return (
    <div className="flex-1 p-4 sm:p-6 overflow-y-auto lg:overflow-hidden flex flex-col gap-4 sm:gap-6">
      {/* Stat Cards Row — 2 columnas en móvil, 4 en desktop */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <StatCard
          label="Activos ahora"
          value={isLoading ? "—" : stats.activeNow}
          unit="sin atender"
          valueClass="text-white"
        />
        <StatCard
          label="Críticos"
          value={isLoading ? "—" : stats.criticalActive}
          unit="activos"
          valueClass="text-stitch-error"
          badge={!isLoading && stats.criticalActive > 0 ? "ATENDER" : undefined}
        />
        <StatCard
          label="En atención"
          value={isLoading ? "—" : stats.inAttention}
          unit="en proceso"
          valueClass="text-stitch-primary"
        />
        <StatCard
          label="Pánico activo"
          value={panicSessions.length}
          unit="sesiones"
          valueClass={
            panicSessions.length > 0 ? "text-red-400" : "text-green-500"
          }
          badge={panicSessions.length > 0 ? "URGENTE" : undefined}
        />
      </div>

      {/* Split: apilado en móvil/tablet, Mapa 65% + Lista 35% en desktop */}
      <div className="flex-1 flex flex-col lg:flex-row gap-4 lg:gap-6 min-h-0">
        {/* Map — altura fija en móvil (apilado), llena en desktop */}
        <section className="w-full lg:w-[65%] h-[55vh] lg:h-auto shrink-0 lg:shrink bg-stitch-surface-container-low rounded-xl relative overflow-hidden flex flex-col">
          <div className="absolute inset-0">
            <IncidentsMap
              incidents={filteredIncidents}
              panicSessions={panicSessions}
              theme="light"
              onPinClick={(id) =>
                navigate({
                  to: "/incidents/$incidentId",
                  params: { incidentId: id },
                })
              }
            />
          </div>

          {/* Legend — clara para legibilidad sobre el mapa light */}
          <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-md p-3 rounded-lg shadow-lg flex flex-col gap-2 z-[1000]">
            {panicSessions.length > 0 && (
              <div className="flex items-center gap-2 pb-2 border-b border-red-500/30">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-500 opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500" />
                </span>
                <span className="text-[10px] font-bold text-red-600 font-label uppercase">
                  Pánico activo · {panicSessions.length}
                </span>
              </div>
            )}
            <div className="flex items-center gap-2">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ background: "#ef4444" }}
              />
              <span className="text-[10px] font-bold text-slate-700 font-label uppercase">
                Prioridad Alta
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ background: "#f59e0b" }}
              />
              <span className="text-[10px] font-bold text-slate-700 font-label uppercase">
                Moderado
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ background: "#22c55e" }}
              />
              <span className="text-[10px] font-bold text-slate-700 font-label uppercase">
                Baja/Informativo
              </span>
            </div>
          </div>
        </section>

        {/* Incident + Panic List */}
        <section className="w-full lg:w-[35%] flex-1 lg:flex-auto flex flex-col gap-4 min-h-0">
          {/* Panic session alerts — always at top when active */}
          {panicSessions.length > 0 && (
            <div className="space-y-2">
              <h2 className="text-xs font-black font-label text-red-400 uppercase tracking-[0.15em] flex items-center gap-2">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-500 opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500" />
                </span>
                Botones de Pánico Activos
              </h2>
              {panicSessions.map((s) => (
                <div
                  key={s.id}
                  className="bg-red-950/40 rounded-xl overflow-hidden border-l-4 border-red-500 p-4 flex items-center gap-3"
                >
                  <span className="text-2xl">🚨</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-red-400">
                      MODO PÁNICO
                    </p>
                    <p className="text-[10px] font-bold text-red-500/70 font-label uppercase">
                      Lat {s.lat.toFixed(4)} · Lng {s.lng.toFixed(4)}
                    </p>
                    <p className="text-[10px] text-red-500/60 font-label">
                      Desde {new Date(s.startedAt).toLocaleTimeString("es-PE")}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="flex flex-col gap-2 xl:justify-between">
            <h2 className="text-xs font-black font-label text-stitch-on-surface-variant uppercase tracking-[0.15em] shrink-0">
              Incidentes Activos
            </h2>
            <div className="flex items-center gap-1 bg-stitch-surface-container-low rounded-lg p-0.5">
              {(Object.keys(SORT_LABEL) as SortMode[]).map((mode) => (
                <button
                  key={mode}
                  onClick={() => setSortMode(mode)}
                  className={`flex-1 xl:flex-none px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider transition-colors whitespace-nowrap ${
                    sortMode === mode
                      ? "bg-stitch-primary-container text-stitch-on-primary-container"
                      : "text-stitch-on-surface-variant hover:text-white"
                  }`}
                >
                  {SORT_LABEL[mode]}
                </button>
              ))}
            </div>
          </div>

          {/* Filter bar with styled inputs */}
          {/* <div className="bg-stitch-surface-container-low rounded-[10px] border border-stitch-outline/20 p-4 flex flex-col gap-3">
            <div className="relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Buscar…"
                className="w-full bg-stitch-surface rounded-md border border-stitch-outline/20 pl-3 pr-3 py-2 text-xs text-white outline-none focus:border-stitch-primary transition-colors placeholder:text-stitch-outline"
              />
            </div>
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5 flex-1 min-w-0">
                <div className="flex-1 min-w-0 bg-stitch-surface rounded-md border border-stitch-outline/20 px-2 py-1 overflow-hidden">
                  <FilterSelect
                    value={typeFilter}
                    onChange={(v) => setTypeFilter(v as IncidentType | 'ALL')}
                    options={TYPE_OPTIONS.map((opt) => ({ value: opt, label: filterTypeLabel(opt) }))}
                  />
                </div>
                <div className="flex-1 min-w-0 bg-stitch-surface rounded-md border border-stitch-outline/20 px-2 py-1 overflow-hidden">
                  <FilterSelect
                    value={severityFilter}
                    onChange={(v) => setSeverityFilter(v as Severity | 'ALL')}
                    options={SEVERITY_OPTIONS.map((opt) => ({ value: opt, label: filterSeverityLabel(opt) }))}
                  />
                </div>
                <div className="flex-1 min-w-0 bg-stitch-surface rounded-md border border-stitch-outline/20 px-2 py-1 overflow-hidden">
                  <FilterSelect
                    value={districtFilter}
                    onChange={(v) => setDistrictFilter(v)}
                    options={DISTRICT_OPTIONS.map((opt) => ({
                      value: opt,
                      label: opt === 'ALL' ? 'Distrito' : opt,
                    }))}
                    icon="location_on"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                {hasActiveFilters && (
                  <button
                    onClick={clearFilters}
                    className="text-stitch-primary text-[10px] font-bold hover:underline shrink-0 uppercase tracking-wider"
                  >
                    Limpiar
                  </button>
                )}
              </div>
            </div>
            <div className="text-[10px] text-stitch-on-surface-variant font-medium">
              {filteredIncidents.length}{' '}
              {filteredIncidents.length === 1 ? 'activo' : 'activos'}
              {hasActiveFilters && ' filtrados'}
            </div>
          </div> */}

          <div className="flex-1 overflow-y-auto space-y-3 pr-2 custom-scrollbar">
            {isLoading && (
              <div className="text-center text-stitch-on-surface-variant py-8 text-xs">
                Cargando incidentes…
              </div>
            )}

            {!isLoading && filteredIncidents.length === 0 && (
              <div className="text-center text-stitch-on-surface-variant py-8 text-xs">
                {hasActiveFilters
                  ? "No hay incidentes activos con los filtros seleccionados."
                  : "No hay incidentes activos en este momento."}
              </div>
            )}

            {filteredIncidents.map((inc) => (
              <IncidentCard
                key={inc.id}
                incident={inc}
                onClick={() =>
                  navigate({
                    to: "/incidents/$incidentId",
                    params: { incidentId: inc.id },
                  })
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
