import { FC } from 'react';
import { Image as ImageIcon, Loader2, AlertCircle } from 'lucide-react';

import { useIncidentEvidence } from '../infrastructure/incidents.api';

interface Props {
  incidentId: string;
}

/**
 * Carrusel de evidencia del incidente. Consume el endpoint autenticado de
 * URLs firmadas (los gs:// crudos NO son renderizables por el navegador).
 * Nunca queda en blanco: muestra estado de carga, error o vacío.
 */
export const EvidenceCarousel: FC<Props> = ({ incidentId }) => {
  const { data, isLoading, isError } = useIncidentEvidence(incidentId);

  const header = (
    <p className="text-[10px] font-bold uppercase tracking-wider text-ay-text-secondary flex items-center gap-1.5">
      <ImageIcon size={12} /> Pruebas adjuntas
    </p>
  );

  if (isLoading) {
    return (
      <div className="pt-1 space-y-2">
        {header}
        <div className="flex items-center gap-2 text-xs text-ay-text-secondary">
          <Loader2 size={14} className="animate-spin" /> Cargando evidencia…
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="pt-1 space-y-2">
        {header}
        <div className="flex items-center gap-2 text-xs text-ay-warn">
          <AlertCircle size={14} /> No se pudo cargar la evidencia.
        </div>
      </div>
    );
  }

  const items = data?.evidence ?? [];

  if (items.length === 0) {
    return (
      <div className="pt-1 space-y-2">
        {header}
        <p className="text-xs text-ay-text-secondary">Sin pruebas visuales disponibles.</p>
      </div>
    );
  }

  return (
    <div className="pt-1 space-y-2">
      <p className="text-[10px] font-bold uppercase tracking-wider text-ay-text-secondary flex items-center gap-1.5">
        <ImageIcon size={12} /> Pruebas adjuntas ({items.length})
      </p>
      <div className="flex gap-2 overflow-x-auto pb-1">
        {items.map((item, i) =>
          item.kind === 'video' ? (
            <video
              key={i}
              src={item.signedUrl}
              controls
              preload="metadata"
              className="h-28 w-auto max-w-[200px] shrink-0 rounded-lg border border-ay-border bg-black"
            />
          ) : (
            <a
              key={i}
              href={item.signedUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="group block shrink-0"
            >
              <img
                src={item.signedUrl}
                alt={`Prueba ${i + 1}`}
                loading="lazy"
                className="h-28 w-28 object-cover rounded-lg border border-ay-border group-hover:border-ay-accent transition-colors"
              />
            </a>
          ),
        )}
      </div>
    </div>
  );
};
