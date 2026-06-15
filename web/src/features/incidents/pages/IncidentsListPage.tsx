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
import {
  FilterSelect,
  TYPE_OPTIONS,
  SEVERITY_OPTIONS,
  STATUS_OPTIONS,
  DISTRICT_OPTIONS,
  DATE_PRESETS,
  todayISO,
  daysAgoISO,
} from "../../../core/components/ui/FilterSelect";

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
  const [statusFilter, setStatusFilter] = useState<IncidentStatus | "ALL">("ALL");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [districtFilter, setDistrictFilter] = useState("ALL");
  const [searchQuery, setSearchQuery] = useState("");

  const query = useMemo(() => {
    const since = dateFrom
      ? new Date(dateFrom + "T00:00:00.000Z").toISOString()
      : undefined;
    return {
      page,
      pageSize: 20,
      status: statusFilter === "ALL" ? ("ALL" as const) : statusFilter,
      ...(severityFilter !== "ALL" && { severity: severityFilter }),
      ...(since && { since }),
      ...(districtFilter !== "ALL" && { district: districtFilter }),
    };
  }, [page, severityFilter, statusFilter, dateFrom, districtFilter]);

  const { data, isLoading, isError, error } = useIncidentsList(query);

  const filtered = useMemo(() => {
    const items = data?.items ?? [];
    return items.filter((i) => {
      if (typeFilter !== "ALL" && i.type !== typeFilter) return false;

      if (dateTo) {
        const endOfDay = new Date(dateTo + "T23:59:59.999Z");
        if (new Date(i.createdAt) > endOfDay) return false;
      }

      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matches =
          i.district.toLowerCase().includes(q) ||
          incidentTypeLabel[i.type].toLowerCase().includes(q) ||
          statusLabel[i.status].toLowerCase().includes(q) ||
          severityLabel[i.severity].toLowerCase().includes(q);
        if (!matches) return false;
      }

      return true;
    });
  }, [data?.items, typeFilter, dateTo, searchQuery]);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / 20)) : 1;
  const activeCount = filtered.filter((i) => i.status === "ACTIVE").length;

  const hasActiveFilters =
    severityFilter !== "ALL" ||
    typeFilter !== "ALL" ||
    statusFilter !== "ALL" ||
    dateFrom !== "" ||
    dateTo !== "" ||
    districtFilter !== "ALL" ||
    searchQuery !== "";

  function clearFilters() {
    setSeverityFilter("ALL");
    setTypeFilter("ALL");
    setStatusFilter("ALL");
    setDateFrom("");
    setDateTo("");
    setDistrictFilter("ALL");
    setSearchQuery("");
    setPage(1);
  }

  function applyDatePreset(preset: string) {
    const today = todayISO();
    switch (preset) {
      case "today":
        setDateFrom(today);
        setDateTo(today);
        break;
      case "yesterday": {
        const yesterday = daysAgoISO(1);
        setDateFrom(yesterday);
        setDateTo(yesterday);
        break;
      }
      case "7d":
        setDateFrom(daysAgoISO(7));
        setDateTo(today);
        break;
      case "30d":
        setDateFrom(daysAgoISO(30));
        setDateTo(today);
        break;
    }
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
      <section className="px-10 mb-6 flex flex-col gap-4">
        {/* Search */}
        <div className="relative">
          <span className="material-symbols-outlined text-[18px] text-stitch-outline absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none">
            search
          </span>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setPage(1);
            }}
            placeholder="Buscar por distrito, tipo, estado…"
            className="w-full bg-ay-bg-dark2 rounded-[10px] border border-ay-border pl-10 pr-4 py-2.5 text-sm text-white outline-none focus:border-ay-accent transition-colors placeholder:text-stitch-outline"
          />
        </div>

        <div className="bg-ay-bg-dark2 rounded-[10px] border border-ay-border p-4 flex flex-col gap-4">
          {/* Dropdown filters left + Date range right */}
          <div className="flex items-start justify-between gap-6">
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
              <div className="w-px h-4 bg-ay-border" />
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
              <div className="w-px h-4 bg-ay-border" />
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
              <div className="w-px h-4 bg-ay-border" />
              <FilterSelect
                value={districtFilter}
                onChange={(v) => {
                  setDistrictFilter(v);
                  setPage(1);
                }}
                options={DISTRICT_OPTIONS.map((opt) => ({
                  value: opt,
                  label: opt === "ALL" ? "Distrito" : opt,
                }))}
                icon="location_on"
              />
            </div>

            <div className="flex items-center gap-2 shrink-0">
              <span className="material-symbols-outlined text-[18px] text-stitch-outline">
                calendar_today
              </span>
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => {
                  setDateFrom(e.target.value);
                  setPage(1);
                }}
                className="bg-ay-bg-dark border border-ay-border rounded px-3 py-1.5 text-sm text-white outline-none focus:border-ay-accent [color-scheme:dark]"
              />
              <span className="text-stitch-outline text-sm">—</span>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => {
                  setDateTo(e.target.value);
                  setPage(1);
                }}
                className="bg-ay-bg-dark border border-ay-border rounded px-3 py-1.5 text-sm text-white outline-none focus:border-ay-accent [color-scheme:dark]"
              />
            </div>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              {DATE_PRESETS.map((preset) => (
                <button
                  key={preset.value}
                  onClick={() => applyDatePreset(preset.value)}
                  className="text-xs font-semibold px-3 py-1.5 rounded-md border border-ay-border text-stitch-outline hover:text-white hover:border-white transition-all"
                >
                  {preset.label}
                </button>
              ))}
            </div>
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="text-ay-accent text-sm font-semibold hover:underline shrink-0"
              >
                Limpiar filtros
              </button>
            )}
          </div>
        </div>

        <div className="flex items-center justify-between">
          <span className="text-[13px] font-medium text-ay-text-sec">
            Mostrando {filtered.length}{" "}
            {filtered.length === 1 ? "incidente" : "incidentes"}
            {hasActiveFilters && " (con filtros aplicados)"}
          </span>
          {searchQuery && filtered.length === 0 && !isLoading && !isError && (
            <span className="text-[13px] text-stitch-outline italic">
              Sin resultados para "{searchQuery}"
            </span>
          )}
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
