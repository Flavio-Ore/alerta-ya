import { useMemo } from 'react';
import type { StatsResponse } from '../../../core/api/types';

const DAY_LABELS = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const HOUR_LABELS = ['06h', '08h', '10h', '12h', '14h', '16h', '18h', '20h', '22h', '00h'];
// Mapear horas del backend a columnas del heatmap
const HOUR_SLOTS = [6, 8, 10, 12, 14, 16, 18, 20, 22, 0];

function heatColor(count: number, max: number): string {
  if (count === 0) return 'bg-[#1E2030]';
  const ratio = max > 0 ? count / max : 0;
  if (ratio < 0.25) return 'bg-[#F5A623]/20';
  if (ratio < 0.5) return 'bg-[#F5A623]/50';
  if (ratio < 0.75) return 'bg-[#F5A623]/80';
  return 'bg-[#EF4444]';
}

interface Props {
  data: StatsResponse['byDayHour'];
}

export function DayHourHeatmap({ data }: Props) {
  const maxCount = useMemo(() => Math.max(...data.map((d) => d.count), 1), [data]);

  const grid = useMemo(() => {
    const map = new Map<string, number>();
    for (const d of data) {
      map.set(`${d.day}:${d.hour}`, d.count);
    }

    return DAY_LABELS.map((_, dayIdx) => {
      // Convertir: backend 0=Dom → display 0=Lun
      const backendDay = dayIdx === 6 ? 0 : dayIdx + 1;
      return HOUR_SLOTS.map((hour) => {
        const count = map.get(`${backendDay}:${hour}`) ?? 0;
        return { day: dayIdx, hour, count };
      });
    });
  }, [data]);

  if (data.length === 0) {
    return (
      <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5">
        <h3 className="text-sm font-bold text-white mb-4">Incidentes por día y hora</h3>
        <p className="text-xs text-stitch-on-surface-variant text-center py-8">
          Sin datos para el período seleccionado
        </p>
      </div>
    );
  }

  return (
    <div className="bg-[#141720] border border-[#2D3A4A] rounded-[12px] p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-bold text-white">Incidentes por día y hora</h3>
        <div className="flex items-center gap-2">
          {[
            { label: 'Bajo', color: 'bg-[#F5A623]/20' },
            { label: 'Medio', color: 'bg-[#F5A623]/50' },
            { label: 'Alto', color: 'bg-[#F5A623]/80' },
            { label: 'Crítico', color: 'bg-[#EF4444]' },
          ].map((lvl) => (
            <div key={lvl.label} className="flex items-center gap-1">
              <span className={`w-3 h-3 rounded ${lvl.color}`} />
              <span className="text-[9px] text-stitch-on-surface-variant uppercase font-label">
                {lvl.label}
              </span>
            </div>
          ))}
        </div>
      </div>
      <div className="overflow-x-auto">
        <div
          className="grid gap-1"
          style={{
            gridTemplateColumns: `60px repeat(${HOUR_SLOTS.length}, minmax(32px, 1fr))`,
          }}
        >
          {/* Header row */}
          <div />
          {HOUR_LABELS.map((h) => (
            <div key={h} className="text-[10px] text-stitch-on-surface-variant text-center font-label">
              {h}
            </div>
          ))}

          {/* Data rows */}
          {grid.map((row, dayIdx) => (
            <>
              <div
                key={`label-${dayIdx}`}
                className="text-[10px] text-stitch-on-surface-variant font-label flex items-center"
              >
                {DAY_LABELS[dayIdx]}
              </div>
              {row.map((cell) => (
                <div
                  key={`${dayIdx}-${cell.hour}`}
                  className={`h-8 rounded ${heatColor(cell.count, maxCount)} flex items-center justify-center cursor-pointer transition-all hover:scale-110 hover:ring-1 hover:ring-white/30`}
                  title={`${DAY_LABELS[dayIdx]} ${cell.hour}:00 — ${cell.count} incidentes`}
                >
                  <span className="text-[9px] text-white/70 font-bold">
                    {cell.count > 0 ? cell.count : ''}
                  </span>
                </div>
              ))}
            </>
          ))}
        </div>
      </div>
    </div>
  );
}
