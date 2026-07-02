import { FC } from 'react';
import { HelpCircle } from 'lucide-react';

import { formatRelativeTime } from '../../features/incidents/presentation/utils/labels';
import type { PublicIncidentDetailDTO } from '../api/types';
import { AiConfidenceBadge } from './AiConfidenceBadge';

interface Props {
  incident: PublicIncidentDetailDTO;
}

const PHOTO_SOURCE_LABEL: Record<string, string> = {
  exif: 'EXIF de la foto',
  device_clock: 'Reloj del dispositivo',
};

/**
 * Panel de desglose de confiabilidad IA. Recalcula has_evidence y photo_age
 * en tiempo de lectura a partir de campos ya persistidos — no consulta de nuevo
 * al verificador ni fabrica datos que no existen (visionMatch = "no disponible").
 */
export const AiBreakdownPanel: FC<Props> = ({ incident }) => {
  const { aiScore, aiVerified, evidence, photoTakenAt, photoSource } = incident;
  const hasEvidence = evidence.some((e) => e.mediaUrls.length > 0);

  // La antigüedad solo es confiable si el timestamp viene de EXIF real. El
  // verificador descarta la frescura cuando photoSource !== 'exif' (device_clock
  // es spoofeable), así que el panel no debe mostrarla como fresca sin marcarla.
  const photoTrusted = photoSource === 'exif';
  const photoAgeLabel = !photoTakenAt
    ? 'sin foto'
    : photoTrusted
      ? formatRelativeTime(photoTakenAt)
      : `${formatRelativeTime(photoTakenAt)} (no verificado)`;

  if (aiScore == null && !hasEvidence) {
    return (
      <div className="bg-ay-bg-dark2 border border-ay-border p-6 flex flex-col items-center justify-center text-center gap-2">
        <HelpCircle size={24} className="text-ay-text-sec" />
        <p className="text-xs font-bold text-white">Sin datos de IA</p>
        <p className="text-[11px] text-ay-text-secondary">
          Este reporte no fue evaluado por el verificador.
        </p>
      </div>
    );
  }

  return (
    <div className="bg-ay-bg-dark2 border border-ay-border p-6 space-y-4">
      <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary">
        Confiabilidad del reporte
      </h3>

      <div className="space-y-3">
        {aiScore != null && (
          <div className="flex justify-between items-center border-b border-ay-border pb-2">
            <span className="text-xs text-ay-text-muted uppercase">Puntaje IA</span>
            <span className="text-xs font-bold text-white">{Math.round(aiScore * 100)}%</span>
          </div>
        )}

        <div className="flex justify-between items-center border-b border-ay-border pb-2">
          <span className="text-xs text-ay-text-muted uppercase">Estado</span>
          <AiConfidenceBadge score={aiScore} verified={aiVerified} />
        </div>

        <div className="flex justify-between items-center border-b border-ay-border pb-2">
          <span className="text-xs text-ay-text-muted uppercase">Evidencia adjunta</span>
          <span className="text-xs font-bold text-white">
            {hasEvidence ? 'Sí' : 'Sin evidencia adjunta'}
          </span>
        </div>

        <div className="flex justify-between items-center border-b border-ay-border pb-2">
          <span className="text-xs text-ay-text-muted uppercase">Antigüedad de la foto</span>
          <span className="text-xs font-bold text-white">{photoAgeLabel}</span>
        </div>

        {photoSource && (
          <div className="flex justify-between items-center border-b border-ay-border pb-2">
            <span className="text-xs text-ay-text-muted uppercase">Fuente del timestamp</span>
            <span className="text-xs font-bold text-white">
              {PHOTO_SOURCE_LABEL[photoSource] ?? photoSource}
            </span>
          </div>
        )}

        <div className="flex justify-between items-center">
          <span className="text-xs text-ay-text-muted uppercase">Coincidencia visual</span>
          <span className="text-xs font-bold text-ay-text-secondary">no disponible</span>
        </div>
      </div>
    </div>
  );
};
