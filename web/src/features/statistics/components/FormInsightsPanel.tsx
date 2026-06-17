import type { StatsResponse } from "../../../core/api/types";

const ESCAPE_COLORS: Record<string, string> = {
  "A pie": "bg-[#4A90D9]",
  Vehículo: "bg-[#F5A623]",
  "No registrado": "bg-[#6B7A8D]",
};

const WEAPON_COLORS: Record<string, string> = {
  "Arma de fuego": "#EF4444",
  "Arma blanca": "#F5A623",
  "Sin arma": "#6B7A8D",
};

function DonutChart({
  data,
  centerValue,
  centerLabel,
}: {
  data: { label: string; pct: number; count: number }[];
  centerValue: string;
  centerLabel: string;
}) {
  const total = data.reduce((s, d) => s + d.pct, 0);
  if (total === 0) {
    return (
      <div className="flex items-center justify-center h-32 text-xs text-stitch-on-surface-variant">
        Sin datos
      </div>
    );
  }

  // Normalize to 100%
  const segments = data.map((d) => ({
    ...d,
    pct: Math.round((d.pct / total) * 100),
  }));

  const conicGradient = segments
    .map((d, i) => {
      const color = WEAPON_COLORS[d.label] ?? "#6B7A8D";
      const startPct = segments.slice(0, i).reduce((s, x) => s + x.pct, 0);
      const endPct = startPct + d.pct;
      return `${color} ${startPct}% ${endPct}%`;
    })
    .join(", ");

  return (
    <div className="relative w-32 h-32 mx-auto">
      <div
        className="w-32 h-32 rounded-full"
        style={{ background: `conic-gradient(${conicGradient})` }}
      >
        <div className="absolute inset-3 bg-[#141720] rounded-full flex flex-col items-center justify-center">
          <span className="text-lg font-headline font-bold text-white">
            {centerValue}
          </span>
          <span className="text-[9px] text-stitch-on-surface-variant uppercase font-label">
            {centerLabel}
          </span>
        </div>
      </div>
    </div>
  );
}

function ProgressBar({
  label,
  pct,
  color,
}: {
  label: string;
  pct: number;
  color: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <div className="flex justify-between text-xs">
        <span className="text-stitch-on-surface-variant">{label}</span>
        <span className="text-white font-bold">{pct}%</span>
      </div>
      <div className="h-2.5 bg-gray-800/30 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full ${color}`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

interface Props {
  data: StatsResponse["formAnalysis"] | undefined;
}

export function FormInsightsPanel({ data }: Props) {
  if (!data) {
    return (
      <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5 animate-pulse h-48" />
    );
  }

  const totalWeapons = data.weaponType.reduce((s, d) => s + d.count, 0);

  return (
    <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5">
      <div className="flex items-center gap-2 mb-6">
        <span className="material-symbols-outlined text-[#F5A623] text-lg">
          insights
        </span>
        <h3 className="text-sm font-bold text-white">
          Análisis de Respuestas — Formulario Dinámico
        </h3>
        <span className="material-symbols-outlined text-xs text-stitch-on-surface-variant ml-auto">
          lock
        </span>
        <span className="text-[10px] text-stitch-on-surface-variant font-label uppercase tracking-wider">
          Sin identidad
        </span>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Col 1 — Tipo de arma (Robos) */}
        <div className="flex flex-col gap-3">
          <h4 className="text-xs font-bold text-white uppercase tracking-wider font-label">
            Tipo de arma (Robos)
          </h4>
          <DonutChart
            data={data.weaponType}
            centerValue={totalWeapons.toString()}
            centerLabel="casos"
          />
          <div className="flex flex-col gap-1.5">
            {data.weaponType.map((w) => (
              <div
                key={w.label}
                className="flex items-center gap-2 text-[11px]"
              >
                <span
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{
                    backgroundColor: WEAPON_COLORS[w.label] ?? "#6B7A8D",
                  }}
                />
                <span className="text-stitch-on-surface-variant">
                  {w.label}
                </span>
                <span className="ml-auto text-white font-bold">{w.pct}%</span>
              </div>
            ))}
          </div>
          {data.weaponType.find(
            (w) => w.label === "Arma de fuego" && w.pct > 50,
          ) && (
            <div className="mt-2 bg-red-900/30 border border-red-500/30 rounded-lg px-3 py-2">
              <div className="flex items-start gap-2">
                <span className="material-symbols-outlined text-[14px] text-stitch-error mt-0.5">
                  warning
                </span>
                <p className="text-[10px] text-stitch-error leading-relaxed">
                  Dato para MININTER: Lima supera el 50% de robos con arma de
                  fuego
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Col 2 — Huida del agresor */}
        <div className="flex flex-col gap-3">
          <h4 className="text-xs font-bold text-white uppercase tracking-wider font-label">
            Huida del agresor
          </h4>
          <div className="flex flex-col gap-3 mt-1">
            {data.escapeMethod.map((e) => (
              <ProgressBar
                key={e.label}
                label={e.label}
                pct={e.pct}
                color={ESCAPE_COLORS[e.label] ?? "bg-[#6B7A8D]"}
              />
            ))}
          </div>
          {data.topVehicleDistrict && (
            <div className="mt-2 bg-amber-900/20 border border-amber-500/30 rounded-lg px-3 py-2">
              <div className="flex items-start gap-2">
                <span className="material-symbols-outlined text-[14px] text-[#F5A623] mt-0.5">
                  directions_car
                </span>
                <p className="text-[10px] text-[#F5A623] leading-relaxed">
                  Vehículo: alta recurrencia en zona {data.topVehicleDistrict}
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Col 3 — Tiempo en zona */}
        <div className="flex flex-col gap-3 relative">
          <h4 className="text-xs font-bold text-white uppercase tracking-wider font-label">
            Tiempo en zona
          </h4>
          <div className="flex-1 flex flex-col items-center justify-center relative">
            {/* Watermark map */}
            <div className="absolute inset-0 flex items-center justify-center opacity-5">
              <span className="material-symbols-outlined text-[120px] text-white">
                map
              </span>
            </div>
            <span className="text-5xl font-headline font-bold text-white z-10">
              {data.stillInZonePct}%
            </span>
            <span className="text-xs text-stitch-on-surface-variant text-center mt-1 z-10">
              Seguían en la zona al reportar
            </span>
            <div className="flex items-center gap-2 mt-3 bg-blue-900/20 border border-blue-500/30 rounded-lg px-3 py-2 z-10">
              <span className="material-symbols-outlined text-[16px] text-blue-400">
                hourglass
              </span>
              <span className="text-[10px] text-blue-400">
                Ventana de intervención: {data.avgResponseMin.toFixed(1)} min
              </span>
            </div>
          </div>
          {/* <div className="text-right mt-2">
            <a
              href="#"
              onClick={(e) => e.preventDefault()}
              className="text-[10px] text-stitch-primary font-bold uppercase tracking-wider hover:underline inline-flex items-center gap-1"
            >
              Ver detalle completo
              <span className="material-symbols-outlined text-[12px]">
                arrow_forward
              </span>
            </a>
          </div> */}
        </div>
      </div>
    </div>
  );
}
