import type { StatsResponse } from "../../../core/api/types";

function KPICard({
  value,
  label,
  icon,
  valueClass,
  trend,
  trendLabel,
}: {
  value: string;
  label: string;
  icon: string;
  valueClass: string;
  trend?: number | null;
  trendLabel?: string;
}) {
  const showTrend = trend !== null && trend !== undefined;
  const isPositive = (trend ?? 0) >= 0;

  return (
    <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] h-20 flex items-center px-5 gap-4">
      <span className="material-symbols-outlined text-[28px] text-stitch-on-surface-variant">
        {icon}
      </span>
      <div className="flex flex-col justify-center">
        <span className={`text-3xl font-headline font-bold ${valueClass}`}>
          {value}
        </span>
        <span className="text-[11px] text-stitch-on-surface-variant font-label uppercase tracking-wider">
          {label}
        </span>
      </div>
      {showTrend && (
        <span
          className={`ml-auto text-[12px] font-bold font-label flex items-center gap-0.5 ${
            isPositive ? "text-green-400" : "text-stitch-error"
          }`}
        >
          <span className="material-symbols-outlined text-[14px]">
            {isPositive ? "trending_up" : "trending_down"}
          </span>
          {isPositive ? "+" : ""}
          {trend}%
          {trendLabel && (
            <span className="text-stitch-on-surface-variant font-normal ml-1">
              {trendLabel}
            </span>
          )}
        </span>
      )}
    </div>
  );
}

export function StatsKPIRow({ data }: { data: StatsResponse | undefined }) {
  if (!data) {
    return (
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 md:gap-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <div
            key={i}
            className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] h-20 animate-pulse"
          />
        ))}
      </div>
    );
  }

  const { kpis } = data.summary;
  const trend = data.comparison?.percentChange;

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 md:gap-4">
      <KPICard
        value={kpis.totalReportes.toString()}
        label="Reportes"
        icon="bar_chart"
        valueClass="text-white"
        trend={trend}
        trendLabel="vs anterior"
      />
      <KPICard
        value={`${kpis.completeFormPct}%`}
        label="Formulario completo"
        icon="check_circle"
        valueClass="text-green-400"
      />
      <KPICard
        value={`${kpis.criticalPct}%`}
        label="Severidad crítico"
        icon="warning"
        valueClass="text-stitch-error"
      />
      <KPICard
        value={`${kpis.aiAccuracyPct}%`}
        label="Precisión verificación IA"
        icon="psychology"
        valueClass="text-[#1B3A6B]"
      />
      <KPICard
        value={`${kpis.avgResponseMin.toFixed(1)} min`}
        label="Tiempo respuesta promedio"
        icon="timer"
        valueClass="text-[#F5A623]"
      />
    </div>
  );
}
