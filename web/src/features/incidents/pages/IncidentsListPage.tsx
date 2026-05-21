import { useMemo, useState } from "react";
import { useNavigate, Link } from "@tanstack/react-router";

import { useIncidentsList } from "../infrastructure/incidents.api";
import { useIncidentLiveUpdates } from "../infrastructure/incidents.socket";
import {
  incidentTypeLabel,
  severityLabel,
  statusLabel,
  formatHHMM,
} from "../presentation/utils/labels";
import type {
  Severity,
  IncidentType,
  IncidentStatus,
} from "../../../core/api/types";

const SEVERITY_OPTIONS: Array<Severity | "ALL"> = [
  "ALL",
  "CRITICAL",
  "MODERATE",
  "LOW",
];
const TYPE_OPTIONS: Array<IncidentType | "ALL"> = [
  "ALL",
  "ROBBERY",
  "ACCIDENT",
  "HARASSMENT",
  "EXTORTION",
  "SUSPICIOUS",
];
const STATUS_OPTIONS: Array<IncidentStatus | "ALL"> = [
  "ALL",
  "ACTIVE",
  "IN_ATTENTION",
  "CLOSED",
];
const SINCE_OPTIONS: Array<{ value: string; label: string }> = [
  { value: "ALL", label: "Cualquier fecha" },
  { value: "24h", label: "Hoy" },
  { value: "7d", label: "Últimos 7 días" },
  { value: "30d", label: "Últimos 30 días" },
];

function sinceToISO(window: string): string | undefined {
  if (window === "ALL") return undefined;
  const now = Date.now();
  const map: Record<string, number> = {
    "24h": 24 * 60 * 60 * 1000,
    "7d": 7 * 24 * 60 * 60 * 1000,
    "30d": 30 * 24 * 60 * 60 * 1000,
  };
  const delta = map[window];
  if (!delta) return undefined;
  return new Date(now - delta).toISOString();
}

// ── Estilos Stitch por severidad / status ─────────────────────────────────────
const SEVERITY_BAR: Record<Severity, string> = {
  CRITICAL: "border-stitch-error",
  MODERATE: "border-stitch-tertiary",
  LOW: "border-green-500",
};
const SEVERITY_TEXT: Record<Severity, string> = {
  CRITICAL: "text-stitch-error",
  MODERATE: "text-stitch-tertiary",
  LOW: "text-green-500",
};
const STATUS_PILL: Record<IncidentStatus, string> = {
  ACTIVE: "bg-green-500/10 text-green-500 border-green-500/30",
  IN_ATTENTION: "bg-blue-500/10 text-blue-400 border-blue-500/30",
  CLOSED:
    "bg-stitch-on-surface-variant/10 text-stitch-on-surface-variant border-stitch-on-surface-variant/30",
};

export default function IncidentsListPage() {
  const navigate = useNavigate();
  useIncidentLiveUpdates();

  const [page, setPage] = useState(1);
  const [severityFilter, setSeverityFilter] = useState<Severity | "ALL">("ALL");
  const [typeFilter, setTypeFilter] = useState<IncidentType | "ALL">("ALL");
  const [statusFilter, setStatusFilter] = useState<IncidentStatus | "ALL">(
    "ALL",
  );
  const [sinceFilter, setSinceFilter] = useState<string>("ALL");

  const query = useMemo(() => {
    const since = sinceToISO(sinceFilter);
    return {
      page,
      pageSize: 20,
      // status va al server: si el user eligió uno específico lo pasamos,
      // si está en ALL pedimos 'ALL' para que el backend NO aplique el default
      // de "solo ACTIVE no expirados" (panel autoridad debe ver TODO el histórico).
      status: statusFilter === "ALL" ? ("ALL" as const) : statusFilter,
      ...(severityFilter !== "ALL" && { severity: severityFilter }),
      ...(since && { since }),
    };
  }, [page, severityFilter, sinceFilter, statusFilter]);

  const { data, isLoading, isError, error } = useIncidentsList(query);

  // Filtro cliente-side: solo type (no soportado por API como query param).
  // status YA viene filtrado del backend.
  const filtered = useMemo(() => {
    const items = data?.items ?? [];
    if (typeFilter === "ALL") return items;
    return items.filter((i) => i.type === typeFilter);
  }, [data?.items, typeFilter]);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / 20)) : 1;
  const activeCount = filtered.filter((i) => i.status === "ACTIVE").length;

  const hasActiveFilters =
    severityFilter !== "ALL" ||
    typeFilter !== "ALL" ||
    statusFilter !== "ALL" ||
    sinceFilter !== "ALL";

  function clearFilters() {
    setSeverityFilter("ALL");
    setTypeFilter("ALL");
    setStatusFilter("ALL");
    setSinceFilter("ALL");
    setPage(1);
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden bg-ay-bg-dark">
      {/* Header */}
      <header className="flex items-center justify-between px-10 py-8">
        <div className="flex flex-col gap-1">
          <h2 className="text-2xl font-bold text-white font-headline tracking-tight">
            Incidentes
          </h2>
          <p className="text-sm text-ay-text-sec font-medium">
            {data?.total ?? "—"} totales ·{" "}
            <span className="text-ay-accent">
              {activeCount} mostrados activos
            </span>
          </p>
        </div>
        <Link
          to="/export"
          className="flex items-center gap-2 px-5 py-2.5 border border-ay-border text-stitch-on-surface rounded-lg hover:bg-stitch-surface-container-high/30 transition-all text-sm font-medium"
        >
          <span className="material-symbols-outlined text-sm">ios_share</span>
          Exportar
        </Link>
      </header>

      {/* Filter Bar */}
      <section className="px-10 mb-6">
        <div className="bg-ay-bg-dark2 rounded-[10px] border border-ay-border p-4 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-4 flex-wrap">
            <FilterSelect
              value={typeFilter}
              onChange={(v) => {
                setTypeFilter(v as IncidentType | "ALL");
                setPage(1);
              }}
              options={TYPE_OPTIONS.map((opt) => ({
                value: opt,
                label:
                  opt === "ALL" ? "Todos los tipos" : incidentTypeLabel[opt],
              }))}
            />
            <div className="w-[1px] h-4 bg-ay-border" />
            <FilterSelect
              value={severityFilter}
              onChange={(v) => {
                setSeverityFilter(v as Severity | "ALL");
                setPage(1);
              }}
              options={SEVERITY_OPTIONS.map((opt) => ({
                value: opt,
                label: opt === "ALL" ? "Severidad" : severityLabel[opt],
              }))}
            />
            <div className="w-[1px] h-4 bg-ay-border" />
            <FilterSelect
              value={statusFilter}
              onChange={(v) => {
                setStatusFilter(v as IncidentStatus | "ALL");
                setPage(1);
              }}
              options={STATUS_OPTIONS.map((opt) => ({
                value: opt,
                label: opt === "ALL" ? "Estado" : statusLabel[opt],
              }))}
            />
            <div className="w-[1px] h-4 bg-ay-border" />
            <FilterSelect
              value={sinceFilter}
              onChange={(v) => {
                setSinceFilter(v);
                setPage(1);
              }}
              options={SINCE_OPTIONS}
              icon="calendar_today"
            />
          </div>

          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="text-ay-accent text-sm font-semibold hover:underline"
            >
              Limpiar filtros
            </button>
          )}
        </div>

        <div className="mt-4">
          <span className="text-[13px] font-medium text-ay-text-sec">
            Mostrando {filtered.length}{" "}
            {filtered.length === 1 ? "incidente" : "incidentes"}
            {hasActiveFilters && " (con filtros aplicados)"}
          </span>
        </div>
      </section>

      {/* Data Table */}
      <section className="flex-1 px-10 overflow-hidden flex flex-col min-h-0">
        <div className="flex-1 overflow-auto rounded-xl border border-ay-border/30 bg-ay-bg-dark2/30">
          <table className="w-full text-left border-collapse">
            <thead className="sticky top-0 bg-ay-bg-dark2 z-10">
              <tr>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Severidad
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Tipo
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Distrito
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Hora
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Estado
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">
                  Reportes
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline text-right">
                  Acción
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ay-border/20">
              {isLoading && (
                <tr>
                  <td
                    colSpan={7}
                    className="px-6 py-12 text-center text-ay-text-sec text-sm"
                  >
                    Cargando incidentes…
                  </td>
                </tr>
              )}

              {isError && (
                <tr>
                  <td
                    colSpan={7}
                    className="px-6 py-12 text-center text-stitch-error text-sm"
                  >
                    <div className="flex items-center justify-center gap-2">
                      <span className="material-symbols-outlined text-base">
                        error
                      </span>
                      {error instanceof Error
                        ? error.message
                        : "Error al cargar incidentes"}
                    </div>
                  </td>
                </tr>
              )}

              {!isLoading && !isError && filtered.length === 0 && (
                <tr>
                  <td
                    colSpan={7}
                    className="px-6 py-12 text-center text-ay-text-sec text-sm"
                  >
                    No hay incidentes con los filtros aplicados.
                  </td>
                </tr>
              )}

              {filtered.map((inc, idx) => (
                <tr
                  key={inc.id}
                  className={`hover:bg-stitch-surface-container-highest/20 transition-colors ${
                    idx % 2 === 0 ? "bg-ay-bg-dark/50" : ""
                  }`}
                >
                  <td
                    className={`px-6 py-4 border-l-[3px] ${SEVERITY_BAR[inc.severity]}`}
                  >
                    <span
                      className={`text-[0.68rem] font-bold tracking-wider ${SEVERITY_TEXT[inc.severity]}`}
                    >
                      {severityLabel[inc.severity].toUpperCase()}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-white">
                    {incidentTypeLabel[inc.type]}
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-outline">
                    {inc.district}
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-outline">
                    {formatHHMM(inc.createdAt)}
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase border ${STATUS_PILL[inc.status]}`}
                    >
                      {statusLabel[inc.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm font-medium text-white">
                    {inc.reportCount}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button
                      onClick={() =>
                        navigate({
                          to: "/incidents/$incidentId",
                          params: { incidentId: inc.id },
                        })
                      }
                      className="text-xs font-bold text-stitch-primary hover:text-white transition-colors tracking-wider"
                    >
                      VER DETALLE
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="py-6 flex justify-center">
          <nav className="flex items-center gap-4 text-xs text-ay-text-sec font-medium">
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              ← Anterior
            </button>
            <span className="text-white">
              Página {page} de {totalPages}
            </span>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              Siguiente →
            </button>
          </nav>
        </div>
      </section>

      {/* Footer — Anonymity reminder */}
      <footer className="h-10 border-t border-ay-border bg-ay-bg-dark2 px-10 flex items-center shrink-0">
        <div className="flex items-center gap-2 text-[11px] text-ay-text-sec">
          <span className="material-symbols-outlined text-sm">lock</span>
          <span>
            Los datos mostrados nunca incluyen la identidad de los reportantes.
            Cumplimiento Ley N° 29733.
          </span>
        </div>
      </footer>
    </div>
  );
}

// ── Componente auxiliar — dropdown con estilo Stitch ──────────────────────────
interface FilterSelectOption {
  value: string;
  label: string;
}

function FilterSelect({
  value,
  onChange,
  options,
  icon,
}: {
  value: string;
  onChange: (v: string) => void;
  options: FilterSelectOption[];
  icon?: string;
}) {
  const isDefault = value === "ALL";
  return (
    <label className="flex items-center gap-2 text-sm cursor-pointer relative">
      {icon && (
        <span className="material-symbols-outlined text-[18px] text-stitch-outline pointer-events-none">
          {icon}
        </span>
      )}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{ backgroundImage: "none" }}
        className={`bg-transparent appearance-none pr-6 pl-0 py-0 border-0 outline-none focus:ring-0 cursor-pointer ${
          isDefault ? "text-stitch-outline" : "text-white font-semibold"
        }`}
      >
        {options.map((opt) => (
          <option
            key={opt.value}
            value={opt.value}
            className="bg-ay-bg-dark2 text-white"
          >
            {opt.label}
          </option>
        ))}
      </select>
      <span className="material-symbols-outlined text-[18px] text-stitch-outline absolute right-0 pointer-events-none">
        expand_more
      </span>
    </label>
  );
}
