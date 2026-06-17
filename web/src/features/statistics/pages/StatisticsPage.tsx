import { useState } from "react";
import type { IncidentType, StatsPeriod } from "../../../core/api/types";
import {
  DISTRICT_OPTIONS,
  FilterSelect,
  TYPE_OPTIONS,
} from "../../../core/components/ui/FilterSelect";
import { incidentTypeLabel } from "../../../features/incidents/presentation/utils/labels";
import { DayHourHeatmap } from "../components/DayHourHeatmap";
import { FormInsightsPanel } from "../components/FormInsightsPanel";
import { IncidentTypeBarChart } from "../components/IncidentTypeBarChart";
import { StatsKPIRow } from "../components/StatsKPIRow";
import { useStats } from "../infrastructure/stats.api";

const PERIOD_PILLS: { label: string; value: StatsPeriod }[] = [
  { label: "Esta semana", value: "7d" },
  { label: "Este mes", value: "30d" },
  { label: "Últimos 3 meses", value: "12m" },
  { label: "Personalizado", value: "all" },
];

const StatisticsPage = () => {
  const [period, setPeriod] = useState<StatsPeriod>("30d");
  const [district, setDistrict] = useState("ALL");
  const [type, setType] = useState<IncidentType | "ALL">("ALL");

  const query = {
    period,
    ...(district !== "ALL" && { district }),
    ...(type !== "ALL" && { type }),
  };

  const { data, isLoading, isError } = useStats(query);

  return (
    <div className="flex-1 p-6 overflow-y-auto flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-headline font-bold text-white">
            Estadísticas
          </h1>
          <p className="text-xs text-stitch-on-surface-variant mt-1 font-label">
            Panel de análisis táctico y operacional
          </p>
        </div>
      </div>

      {/* Filter row */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-1 bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-1">
          {PERIOD_PILLS.map((pill) => (
            <button
              key={pill.value}
              onClick={() => setPeriod(pill.value)}
              className={`px-4 py-2 rounded-lg text-xs font-bold font-label uppercase tracking-wider transition-all ${
                period === pill.value
                  ? "bg-stitch-primary text-[#0D1B2A]"
                  : "text-stitch-on-surface-variant hover:text-white"
              }`}
            >
              {pill.label}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1 text-xs text-stitch-on-surface-variant">
            <span className="material-symbols-outlined text-[16px]">
              location_on
            </span>
            <span className="font-bold">Lima · </span>
          </div>
          <FilterSelect
            value={district}
            onChange={setDistrict}
            options={DISTRICT_OPTIONS.map((opt) => ({
              value: opt,
              label: opt === "ALL" ? "Todos" : opt,
            }))}
          />
          <FilterSelect
            value={type}
            onChange={(v) => setType(v as IncidentType | "ALL")}
            options={TYPE_OPTIONS.map((opt) => ({
              value: opt,
              label:
                opt === "ALL" ? "Tipo" : incidentTypeLabel[opt as IncidentType],
            }))}
            icon="category"
          />
        </div>
      </div>

      {/* KPI Row */}
      <StatsKPIRow data={data} />

      {/* Error state */}
      {isError && (
        <div className="flex items-center justify-center py-20">
          <div className="flex flex-col items-center gap-3">
            <span className="material-symbols-outlined text-4xl text-stitch-error">
              error
            </span>
            <p className="text-xs text-stitch-error font-bold uppercase tracking-widest font-label">
              Error al cargar estadísticas
            </p>
            <p className="text-xs text-stitch-on-surface-variant">
              Verifica que el backend esté disponible y tengas permisos de
              autoridad
            </p>
          </div>
        </div>
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="flex items-center justify-center py-20">
          <div className="flex flex-col items-center gap-3">
            <span className="material-symbols-outlined text-4xl text-stitch-primary animate-pulse">
              bar_chart
            </span>
            <p className="text-xs text-stitch-on-surface-variant font-bold uppercase tracking-widest font-label">
              Cargando estadísticas…
            </p>
          </div>
        </div>
      )}

      {/* Charts */}
      {!isLoading && !isError && (
        <>
          <div className="grid grid-cols-2 gap-6">
            <IncidentTypeBarChart data={data?.byType ?? []} />
            <DayHourHeatmap data={data?.byDayHour ?? []} />
          </div>

          <FormInsightsPanel data={data?.formAnalysis} />
        </>
      )}
    </div>
  );
};
export default StatisticsPage;
