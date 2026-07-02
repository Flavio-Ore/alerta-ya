import { FC } from 'react';

import type { ReporterTrustTier } from '../api/types';

interface Props {
  /** Tier agregado de reportantes. null/undefined → sin dato, no se muestra nada. */
  tier?: ReporterTrustTier | null;
}

const TIER_META: Record<ReporterTrustTier, { label: string; icon: string; cls: string; title: string }> = {
  high: {
    label: 'Reportantes confiables',
    icon: 'shield_person',
    cls: 'bg-green-500/10 text-green-400 border-green-500/20',
    title: 'Historial verificado sostenido — mayor seguridad para el lector',
  },
  medium: {
    label: 'Reportantes habituales',
    icon: 'person',
    cls: 'bg-sky-500/10 text-sky-400 border-sky-500/20',
    title: 'Reputación normal de la comunidad',
  },
  low: {
    label: 'Reportantes nuevos',
    icon: 'person_alert',
    cls: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
    title: 'Poca trayectoria o reportes dudosos — contrastar con otras fuentes',
  },
};

/**
 * Badge anónimo de confianza de los reportantes de un incidente.
 * NUNCA muestra el puntaje ni la identidad: solo la banda de 3 niveles,
 * para dar seguridad a otros usuarios. No renderiza nada si no hay dato.
 */
export const ReporterTrustBadge: FC<Props> = ({ tier }) => {
  if (tier == null) return null;
  const meta = TIER_META[tier];

  return (
    <span
      className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded border ${meta.cls}`}
      title={meta.title}
    >
      <span className="material-symbols-outlined text-[12px] leading-none">{meta.icon}</span>
      {meta.label}
    </span>
  );
};
