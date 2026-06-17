import type { IncidentType, StatsResponse } from "../../../core/api/types";
import { incidentTypeLabel } from "../../../features/incidents/presentation/utils/labels";

const TYPE_STYLE: Record<IncidentType, { bar: string; text: string }> = {
  ROBBERY: { bar: "bg-[#EF4444]", text: "text-[#EF4444]" },
  ACCIDENT: { bar: "bg-[#F5A623]", text: "text-[#F5A623]" },
  SUSPICIOUS: { bar: "bg-[#6B7A8D]", text: "text-[#6B7A8D]" },
  HARASSMENT: { bar: "bg-[#FF9100]", text: "text-[#FF9100]" },
  EXTORTION: { bar: "bg-[#F5A623]/60", text: "text-[#F5A623]/60" },
};

const TYPE_ORDER: IncidentType[] = [
  "ROBBERY",
  "ACCIDENT",
  "SUSPICIOUS",
  "HARASSMENT",
  "EXTORTION",
];

interface Props {
  data: StatsResponse["byType"];
}

export function IncidentTypeBarChart({ data }: Props) {
  const maxCount = Math.max(...data.map((d) => d.count), 1);

  const sorted = TYPE_ORDER.map((type) => {
    const found = data.find((d) => d.type === type);
    return { type, count: found?.count ?? 0, label: incidentTypeLabel[type] };
  }).filter((d) => d.count > 0);

  if (sorted.length === 0) {
    return (
      <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5">
        <h3 className="text-sm font-bold text-white mb-4">
          Reportes por tipo de incidente
        </h3>
        <p className="text-xs text-stitch-on-surface-variant text-center py-8">
          Sin datos para el período seleccionado
        </p>
      </div>
    );
  }

  return (
    <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-bold text-white">
          Reportes por tipo de incidente
        </h3>
        <span className="text-[10px] font-bold text-stitch-error uppercase tracking-wider font-label">
          [EN TIEMPO REAL]
        </span>
      </div>
      <div className="flex flex-col gap-3">
        {sorted.map(({ type, count, label }) => {
          const pct = maxCount > 0 ? Math.round((count / maxCount) * 100) : 0;
          const style = TYPE_STYLE[type];
          return (
            <div key={type} className="flex items-center gap-3">
              <span className="w-32 text-xs text-stitch-on-surface-variant font-medium shrink-0">
                {label}
              </span>
              <div className="flex-1 h-7 bg-gray-800/30 rounded-r overflow-hidden relative">
                <div
                  className={`h-full rounded-r ${style.bar} transition-all duration-500`}
                  style={{ width: `${Math.max(pct, 3)}%` }}
                />
              </div>
              <span
                className={`w-16 text-right text-xs font-bold ${style.text} shrink-0`}
              >
                {count} reportes
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
