import { ArrowLeft, Clock, MapPin } from 'lucide-react';
import { useParams, useNavigate, useRouterState } from '@tanstack/react-router';

import { usePanicSessionDetail } from '../infrastructure/panic.api';
import { RecordingPlayer } from '../components/RecordingPlayer';
import { IncidentsMap } from '../../dashboard/components/IncidentsMap';
import { formatRelativeTime, formatHHMM } from '../../incidents/presentation/utils/labels';
import type { PanicSessionSummaryDTO, PanicSessionStatus, PublicIncidentDTO } from '../../../core/api/types';

const STATUS_LABEL: Record<PanicSessionStatus, string> = {
  ACTIVE: 'Activo',
  DEACTIVATED: 'Desactivado',
  TIMEOUT: 'Expirado',
};

const NO_INCIDENTS: PublicIncidentDTO[] = [];

export default function PanicSessionDetailPage() {
  const { sessionId } = useParams({ strict: false }) as { sessionId: string };
  const navigate = useNavigate();
  const routerState = useRouterState({ select: (s) => s.location.state as { session?: PanicSessionSummaryDTO } });

  // Fallback: si no llegó por navegación desde la lista (ej. recarga de página
  // o deep-link), pide la sesión puntual por id — sirve tanto para sesiones
  // recientes como para cualquier sesión histórica.
  const needsFallback = !routerState?.session;
  const { data, isLoading, isError } = usePanicSessionDetail(needsFallback ? sessionId : undefined);
  const session = routerState?.session ?? data;

  if (needsFallback && isLoading) {
    return (
      <div className="flex-1 overflow-auto p-8 bg-stitch-surface text-center text-stitch-on-surface-variant">
        Cargando sesión…
      </div>
    );
  }

  if ((needsFallback && isError) || !session) {
    return (
      <div className="flex-1 overflow-auto p-8 bg-stitch-surface">
        <div className="flex items-center gap-2 text-stitch-error bg-stitch-error/10 border border-stitch-error/30 p-4">
          No se pudo cargar la sesión de pánico.
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-4 md:p-8 space-y-6 bg-stitch-surface">
      <button
        onClick={() => navigate({ to: '/panic' })}
        className="flex items-center gap-2 text-xs text-ay-text-secondary hover:text-white transition-colors"
      >
        <ArrowLeft size={14} /> Volver al listado
      </button>

      <div className="flex flex-col sm:flex-row justify-between items-start gap-3 p-4 md:p-6 border border-ay-critical/30 bg-ay-critical/10">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tighter">
            Sesión de pánico
          </h1>
          <p className="text-xs text-ay-text-secondary flex items-center gap-2 mt-1">
            <Clock size={14} /> Iniciada {formatRelativeTime(session.startedAt)} · {formatHHMM(session.startedAt)} hrs
          </p>
          {session.endedAt && (
            <p className="text-xs text-ay-text-secondary flex items-center gap-2 mt-1">
              Finalizada {formatRelativeTime(session.endedAt)} · {formatHHMM(session.endedAt)} hrs
              {session.deactivatedBy && ` (${session.deactivatedBy})`}
            </p>
          )}
        </div>
        <span className="text-sm font-black px-3 py-1 bg-ay-bg-dark2 text-white border border-ay-border">
          {STATUS_LABEL[session.status]}
        </span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 h-64 rounded-xl overflow-hidden relative">
          <IncidentsMap
            incidents={NO_INCIDENTS}
            panicSessions={[session]}
            theme="light"
            center={[session.lat, session.lng]}
            zoom={15}
          />
          <div className="absolute bottom-2 right-2 bg-stitch-surface/90 backdrop-blur-md px-3 py-1.5 rounded text-[10px] font-mono text-stitch-on-surface z-[1000] flex items-center gap-1">
            <MapPin size={12} /> {session.lat.toFixed(5)}, {session.lng.toFixed(5)}
          </div>
        </div>

        <div className="bg-ay-bg-dark2 border border-ay-border p-6 space-y-4">
          <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary">
            Grabación de audio
          </h3>
          <RecordingPlayer sessionId={session.id} recordingBlocksCount={session.recordingBlocksCount} />
        </div>
      </div>

      <div className="flex justify-end pt-4">
        <p className="text-[10px] font-bold text-ay-text-secondary uppercase">
          Identidad del ciudadano cifrada · Acceso auditado
        </p>
      </div>
    </div>
  );
}
