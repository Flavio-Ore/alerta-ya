import { useEffect, useState } from "react";

import {
  RiskHeatMap,
  riskColor,
  type RiskZone,
} from "../components/RiskHeatMap";
import { AiAnalystChat } from "../components/AiAnalystChat";

interface District {
  district: string;
  risk: number;
  count: number;
  zones: number;
}

interface CrimeType {
  type: string;
  count: number;
}

/** Hook mínimo para leer un JSON estático desde /public/data. */
function useJson<T>(url: string): T | null {
  const [data, setData] = useState<T | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(url)
      .then((r) => r.json())
      .then((d: T) => {
        if (alive) setData(d);
      })
      .catch(() => {
        /* silencioso: archivo aún no generado */
      });
    return () => {
      alive = false;
    };
  }, [url]);
  return data;
}

function KpiCard({
  label,
  value,
  unit,
}: {
  label: string;
  value: string | number;
  unit: string;
}) {
  // Números → grandes y prominentes. Texto largo (nombre de distrito) → más
  // chico con leading apretado, para que las 4 cards se vean balanceadas.
  const isText = typeof value === 'string';

  return (
    <div className="bg-stitch-surface-container rounded-xl border border-stitch-outline-variant p-5 flex flex-col">
      <p className="text-[10px] font-bold text-stitch-on-surface-variant uppercase tracking-widest mb-2">
        {label}
      </p>
      <div className="mt-auto flex items-baseline gap-2 min-h-[2.75rem]">
        <span
          className={`font-bold text-white ${
            isText ? 'text-lg leading-tight' : 'text-3xl leading-none'
          }`}
        >
          {value}
        </span>
        {unit && <span className="text-xs text-stitch-on-surface-variant shrink-0">{unit}</span>}
      </div>
    </div>
  );
}

export default function StatisticsPage() {
  const zones = useJson<RiskZone[]>("/data/zones.json");
  const districts = useJson<District[]>("/data/districts.json");
  const types = useJson<CrimeType[]>("/data/types.json");

  const loading = !zones || !districts || !types;

  if (loading) {
    return (
      <div className="flex-1 grid place-items-center bg-stitch-surface text-stitch-on-surface-variant text-sm">
        Cargando estadísticas…
      </div>
    );
  }

  const totalCasos = zones.reduce((acc, z) => acc + z.count, 0);
  const maxType = Math.max(...types.map((t) => t.count), 1);

  return (
    <div className="flex-1 overflow-y-auto bg-stitch-surface text-stitch-on-surface p-6 flex flex-col gap-6">
      {/* Header honesto */}
      <header className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">
            Mapa de Riesgo — Histórico
          </h1>
          <p className="text-sm text-stitch-on-surface-variant mt-1">
            Dónde se concentran las denuncias en Lima. Riesgo por zona (0–100)
            según conteo histórico.
          </p>
        </div>
        <span className="shrink-0 text-[10px] font-bold uppercase tracking-wider text-stitch-tertiary bg-stitch-tertiary-container/40 border border-stitch-tertiary/30 px-3 py-1.5 rounded-lg">
          Histórico
        </span>
      </header>

      {/* Banner de fuente honesto */}
      <div className="bg-stitch-primary-container/25 border border-stitch-primary/20 rounded-lg px-4 py-2.5 text-xs text-stitch-primary flex items-center gap-2">
        <span className="material-symbols-outlined text-base">info</span>
        Fuente: DataCrim (INEI) · denuncias 2017–2020. El conteo crudo favorece
        zonas más pobladas.
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-4 gap-4">
        <KpiCard
          label="Denuncias"
          value={totalCasos.toLocaleString("es-PE")}
          unit="casos"
        />
        <KpiCard
          label="Zonas analizadas"
          value={zones.length.toLocaleString("es-PE")}
          unit="celdas"
        />
        <KpiCard label="Distritos" value={districts.length} unit="con datos" />
        <KpiCard
          label="Mayor riesgo"
          value={districts[0]?.district ?? "—"}
          unit=""
        />
      </div>

      {/* Mapa + Ranking */}
      <div className="grid grid-cols-3 gap-6 h-fit">
        {/* Mapa de calor — tiles claros (intencional, contraste con panel oscuro) */}
        <section className="col-span-2 bg-stitch-surface-container rounded-xl border border-stitch-outline-variant overflow-hidden relative">
          <div className="absolute inset-0">
            <RiskHeatMap zones={zones} />
          </div>
          {/* Leyenda */}
          <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur p-3 rounded-lg shadow z-[1000] flex flex-col gap-1.5">
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">
              Riesgo
            </span>
            {[
              { c: "#22c55e", t: "Bajo" },
              { c: "#f59e0b", t: "Moderado" },
              { c: "#ef4444", t: "Crítico" },
            ].map((l) => (
              <div key={l.t} className="flex items-center gap-2">
                <span
                  className="w-3 h-3 rounded-full"
                  style={{ background: l.c }}
                />
                <span className="text-[11px] text-slate-600">{l.t}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Ranking de distritos */}
        <section className="bg-stitch-surface-container rounded-xl border border-stitch-outline-variant p-5 flex flex-col">
          <h2 className="text-xs font-bold text-stitch-on-surface-variant uppercase tracking-widest mb-4">
            Ranking de riesgo
          </h2>
          <div className="flex-1 min-h-0 flex flex-col gap-3 overflow-y-auto pr-1">
            {districts.slice(0, 12).map((d, i) => (
              <div key={d.district}>
                <div className="flex justify-between items-baseline mb-1">
                  <span className="text-sm font-semibold text-stitch-on-surface">
                    {i + 1}. {d.district}
                  </span>
                  <span
                    className="text-sm font-bold"
                    style={{ color: riskColor(d.risk) }}
                  >
                    {d.risk}%
                  </span>
                </div>
                <div className="h-2 bg-stitch-surface-container-high rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${d.risk}%`,
                      background: riskColor(d.risk),
                    }}
                  />
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Desglose por tipo de delito */}
      <section className="bg-stitch-surface-container rounded-xl border border-stitch-outline-variant p-5">
        <h2 className="text-xs font-bold text-stitch-on-surface-variant uppercase tracking-widest mb-4">
          Tipos de delito
        </h2>
        <div className="grid grid-cols-2 gap-x-8 gap-y-3">
          {types.map((t) => (
            <div key={t.type}>
              <div className="flex justify-between items-baseline mb-1">
                <span className="text-xs font-medium text-stitch-on-surface truncate pr-2">
                  {t.type}
                </span>
                <span className="text-xs font-bold text-stitch-on-surface-variant">
                  {t.count.toLocaleString("es-PE")}
                </span>
              </div>
              <div className="h-1.5 bg-stitch-surface-container-high rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full bg-stitch-primary"
                  style={{ width: `${(t.count / maxType) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Asistente de análisis IA — anclado a los datos históricos reales */}
      <AiAnalystChat districts={districts} types={types} />

      <footer className="text-center text-[11px] text-stitch-on-surface-variant/60 pb-2">
        Riesgo histórico basado en denuncias de 2017–2020
      </footer>
    </div>
  );
}
