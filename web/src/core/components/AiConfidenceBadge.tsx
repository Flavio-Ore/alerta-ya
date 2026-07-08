import { FC } from 'react';

import { aiVerdict, type AiState } from '../../features/incidents/utils/aiVerdict';

interface Props {
  /** Confianza del verificador ML (0–1). null/undefined → la IA no corrió. */
  score?: number | null;
  /** true si el reporte pasó el verificador; false = sospechoso; null = sin evaluar. */
  verified?: boolean | null;
}

const STATE_CONFIG: Record<
  AiState,
  { label: string; icon: string; cls: string; title: string }
> = {
  verified: {
    label: 'Verificado por IA',
    icon: 'verified',
    cls: 'bg-ay-primary/10 text-ay-primary border-ay-primary/20',
    title: 'Reporte verificado por IA',
  },
  suspicious: {
    label: 'Sospechoso — revisar',
    icon: 'gpp_maybe',
    cls: 'bg-ay-warn/10 text-ay-warn border-ay-warn/20',
    title: 'Reporte marcado como sospechoso por IA — revisar',
  },
  'not-evaluated': {
    label: 'Sin evaluar por IA',
    icon: 'help',
    cls: 'bg-ay-text-sec/10 text-ay-text-sec border-ay-text-sec/20',
    title: 'Este reporte todavía no fue evaluado por el verificador IA',
  },
};

/**
 * Badge de confiabilidad IA del incidente — 3 estados: verificado / sospechoso / sin evaluar.
 * Eje visualmente distinto del de severidad (no reutiliza ay-low/ay-moderate/ay-critical).
 */
export const AiConfidenceBadge: FC<Props> = ({ score, verified }) => {
  const state = aiVerdict(score, verified);
  const { label, icon, cls, title } = STATE_CONFIG[state];
  const pctSuffix = score != null ? ` (${Math.round(score * 100)}%)` : '';

  return (
    <span
      className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded border ${cls}`}
      title={title}
    >
      <span className="material-symbols-outlined text-[12px] leading-none">{icon}</span>
      {label}
      {pctSuffix}
    </span>
  );
};
