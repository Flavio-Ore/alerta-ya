import { FC } from 'react';

interface Props {
  /** Confianza del verificador ML (0–1). null/undefined → la IA no corrió, no se muestra nada. */
  score?: number | null;
  /** true si el reporte pasó el verificador. */
  verified?: boolean | null;
}

/**
 * Badge de confianza del verificador IA en un incidente.
 * Verde = verificado/coherente · Rojo = marcado como sospechoso.
 * No muestra nada si la IA no corrió (score null) — honestidad sobre la disponibilidad.
 */
export const AiConfidenceBadge: FC<Props> = ({ score, verified }) => {
  if (score == null) return null;

  const pct = Math.round(score * 100);
  const ok = verified !== false;
  const cls = ok
    ? 'bg-green-500/10 text-green-400 border-green-500/20'
    : 'bg-stitch-error/10 text-stitch-error border-stitch-error/20';

  return (
    <span
      className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded border ${cls}`}
      title={ok ? 'Reporte verificado por IA' : 'Reporte marcado como sospechoso por IA — revisar'}
    >
      <span className="material-symbols-outlined text-[12px] leading-none">
        {ok ? 'verified' : 'gpp_maybe'}
      </span>
      IA {pct}%
    </span>
  );
};
