import { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from '@tanstack/react-router';
import { Siren, History, CheckCircle2, Clock, ArrowLeft, AlertCircle, FileText, Image as ImageIcon, Music, ExternalLink } from 'lucide-react';

import { useIncidentDetail, useUpdateIncidentStatus } from '../infrastructure/incidents.api';
import { IncidentsMap } from '../../dashboard/components/IncidentsMap';
import { AiBreakdownPanel } from '../../../core/components/AiBreakdownPanel';
import {
  incidentTypeLabel,
  severityLabel,
  severityClass,
  statusLabel,
  statusClass,
  formatRelativeTime,
  formatHHMM,
} from '../presentation/utils/labels';
import type { IncidentStatus } from '../../../core/api/types';
import { parseFormData } from '../presentation/utils/form-labels';

/** Detecta el tipo de media por la extensión de la URL (Cloudinary). */
function mediaKind(url: string): 'image' | 'video' | 'audio' | 'other' {
  const clean = url.split('?')[0].toLowerCase();
  if (/\.(jpe?g|png|webp|gif|avif|heic)$/.test(clean)) return 'image';
  if (/\.(mp4|webm|mov|m4v)$/.test(clean)) return 'video';
  if (/\.(mp3|wav|m4a|aac|ogg)$/.test(clean)) return 'audio';
  return 'other';
}

/** Thumbnail de una prueba adjunta. Imagen/video se previsualizan; audio/otros como chip. */
function EvidenceMedia({ url, index }: { url: string; index: number }) {
  const kind = mediaKind(url);

  if (kind === 'image') {
    return (
      <a href={url} target="_blank" rel="noopener noreferrer" className="group block">
        <img
          src={url}
          alt={`Prueba ${index + 1}`}
          loading="lazy"
          className="h-28 w-28 object-cover rounded-lg border border-ay-border group-hover:border-ay-accent transition-colors"
        />
      </a>
    );
  }

  if (kind === 'video') {
    return (
      <video
        src={url}
        controls
        preload="metadata"
        className="h-28 w-auto max-w-[200px] rounded-lg border border-ay-border bg-black"
      />
    );
  }

  const Icon = kind === 'audio' ? Music : ExternalLink;
  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="h-28 w-28 flex flex-col items-center justify-center gap-2 rounded-lg border border-ay-border text-ay-text-secondary hover:border-ay-accent hover:text-ay-accent transition-colors"
    >
      <Icon size={22} />
      <span className="text-[10px] font-bold uppercase">
        {kind === 'audio' ? 'Audio' : `Adjunto ${index + 1}`}
      </span>
    </a>
  );
}

export default function IncidentDetailPage() {
  const { incidentId } = useParams({ strict: false }) as { incidentId: string };
  const navigate = useNavigate();
  const { data: incident, isLoading, isError, error } = useIncidentDetail(incidentId);
  const updateStatus = useUpdateIncidentStatus();

  const [feedback, setFeedback] = useState('');
  const prefillDoneRef = useRef<string | null>(null);

  // Pre-cargar el feedback SOLO la primera vez que carga un incidente (por id).
  // No volver a correr en refetches: onSuccess del mutate limpia el input.
  useEffect(() => {
    if (incident?.id && prefillDoneRef.current !== incident.id) {
      prefillDoneRef.current = incident.id;
      setFeedback(incident.feedback ?? '');
    }
  }, [incident?.id, incident?.feedback]);

  if (isLoading) {
    return (
      <div className="flex-1 overflow-auto p-8 bg-stitch-surface text-center text-stitch-on-surface-variant">
        Cargando incidente…
      </div>
    );
  }

  if (isError || !incident) {
    return (
      <div className="flex-1 overflow-auto p-8 bg-stitch-surface">
        <div className="flex items-center gap-2 text-stitch-error bg-stitch-error/10 border border-stitch-error/30 p-4">
          <AlertCircle size={16} />
          {error instanceof Error ? error.message : 'No se pudo cargar el incidente'}
        </div>
      </div>
    );
  }

  const sev = severityClass[incident.severity];
  const st = statusClass[incident.status];
  const isClosed = incident.status === 'CLOSED';

  function handleStatusChange(newStatus: IncidentStatus) {
    updateStatus.mutate(
      { id: incidentId, input: { status: newStatus, ...(feedback && { feedback }) } },
      {
        onSuccess: () => setFeedback(''),
      },
    );
  }

  const validation = incident.confirmCount + incident.denyCount > 0
    ? Math.round((incident.confirmCount / (incident.confirmCount + incident.denyCount)) * 100)
    : 0;

  return (
    <div className="flex-1 overflow-auto p-4 md:p-8 space-y-6 bg-stitch-surface">
      <button
        onClick={() => navigate({ to: '/incidents' })}
        className="flex items-center gap-2 text-xs text-ay-text-secondary hover:text-white transition-colors"
      >
        <ArrowLeft size={14} /> Volver a la lista
      </button>

      <div className={`flex flex-col sm:flex-row justify-between items-start gap-3 p-4 md:p-6 border ${sev.bg} ${sev.border}`}>
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div className="flex flex-col gap-0.5">
              <span className="text-[9px] font-bold uppercase tracking-widest text-ay-text-secondary">
                Gravedad, según reportes
              </span>
              <span className={`text-xs font-black px-3 py-1 uppercase ${sev.text} ${sev.bg} border ${sev.border} w-fit`}>
                {severityLabel[incident.severity]}
              </span>
            </div>
            <h1 className="text-2xl font-bold text-white tracking-tighter">
              {incidentTypeLabel[incident.type]} · {incident.district}
            </h1>
          </div>
          <p className="text-xs text-ay-text-secondary flex items-center gap-2">
            <Clock size={14} /> Reportado {formatRelativeTime(incident.createdAt)} · {formatHHMM(incident.createdAt)} hrs
          </p>
        </div>
        <div className="text-right">
          <p className="text-[10px] font-bold text-ay-text-secondary uppercase tracking-[0.2em] mb-1">
            Estado
          </p>
          <span className={`text-sm font-black px-3 py-1 ${st.bg} ${st.text} border ${st.border}`}>
            {statusLabel[incident.status].toUpperCase()}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="h-64 rounded-xl overflow-hidden relative">
            <IncidentsMap
              incidents={[incident]}
              theme="light"
              center={[incident.lat, incident.lng]}
              zoom={15}
              highlightId={incident.id}
              showHeatmap={false}
            />
            <div className="absolute bottom-2 right-2 bg-stitch-surface/90 backdrop-blur-md px-3 py-1.5 rounded text-[10px] font-mono text-stitch-on-surface z-[1000]">
              {incident.lat.toFixed(5)}, {incident.lng.toFixed(5)}
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="bg-ay-bg-dark2 p-6 border border-ay-border space-y-4">
              <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary">
                Inteligencia Ciudadana
              </h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center border-b border-ay-border pb-2">
                  <span className="text-xs text-ay-text-muted uppercase">Reportes totales</span>
                  <span className="text-xs font-bold text-white">{incident.reportCount}</span>
                </div>
                <div className="flex justify-between items-center border-b border-ay-border pb-2">
                  <span className="text-xs text-ay-text-muted uppercase">Reportes con arma</span>
                  <span className={`text-xs font-bold uppercase flex items-center gap-1 ${incident.weaponReports > 0 ? 'text-ay-critical' : 'text-ay-text-secondary'}`}>
                    {incident.weaponReports > 0 && <Siren size={12} />}
                    {incident.weaponReports}
                  </span>
                </div>
                <div className="flex justify-between items-center border-b border-ay-border pb-2">
                  <span className="text-xs text-ay-text-muted uppercase">Heridos reportados</span>
                  <span className="text-xs font-bold text-white">{incident.injuredReports}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-ay-text-muted uppercase">"Sigue ahí"</span>
                  <span className="text-xs font-bold text-ay-accent">
                    {incident.stillHereReports} confirmaciones
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-ay-bg-dark2 p-6 border border-ay-border flex flex-col items-center justify-center text-center">
              <div className="h-20 w-20 rounded-full border-4 border-ay-primary flex items-center justify-center mb-3">
                <span className="text-2xl font-black text-white">{validation}%</span>
              </div>
              <p className="text-xs font-bold uppercase tracking-tighter text-ay-primary mb-1">
                Validación Social
              </p>
              <p className="text-[10px] text-ay-text-secondary uppercase">
                {incident.confirmCount} confirman / {incident.denyCount} desestiman
              </p>
            </div>
          </div>

          {incident.evidence.length > 0 && (
            <div className="bg-ay-bg-dark2 border border-ay-border p-6 space-y-4">
              <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary flex items-center gap-2">
                <FileText size={14} /> Evidencia agregada ({incident.evidence.length} reportes)
              </h3>
              <div className="space-y-3">
                {incident.evidence.map((ev, idx) => {
                  const fields = parseFormData(ev.formData);
                  const chips = fields.filter((f) => !f.isFreeText);
                  const notes = fields.filter((f) => f.isFreeText);
                  return (
                    <div key={idx} className="bg-ay-bg-dark border border-ay-border p-4 space-y-3">
                      <p className="text-[10px] font-bold uppercase tracking-wider text-ay-text-secondary">
                        Reporte #{idx + 1}
                      </p>

                      {chips.length > 0 && (
                        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3">
                          {chips.map((f) => (
                            <div key={f.key} className="flex flex-col gap-1.5">
                              <dt className="text-[10px] uppercase tracking-wider text-ay-text-secondary">
                                {f.label}
                              </dt>
                              <dd>
                                <span
                                  className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-md ${
                                    f.isDanger
                                      ? 'bg-ay-critical/15 text-ay-critical border border-ay-critical/30'
                                      : 'bg-ay-border/40 text-white'
                                  }`}
                                >
                                  {f.isDanger && <Siren size={11} />}
                                  {f.value}
                                </span>
                              </dd>
                            </div>
                          ))}
                        </dl>
                      )}

                      {notes.map((f) => (
                        <div key={f.key} className="border-l-2 border-ay-accent pl-3">
                          <p className="text-[10px] uppercase tracking-wider text-ay-text-secondary mb-1">
                            {f.label}
                          </p>
                          <p className="text-xs text-white italic leading-relaxed">"{f.value}"</p>
                        </div>
                      ))}

                      {ev.mediaUrls.length > 0 && (
                        <div className="pt-1 space-y-2">
                          <p className="text-[10px] font-bold uppercase tracking-wider text-ay-text-secondary flex items-center gap-1.5">
                            <ImageIcon size={12} /> Pruebas adjuntas ({ev.mediaUrls.length})
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {ev.mediaUrls.map((url, i) => (
                              <EvidenceMedia key={i} url={url} index={i} />
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        <div className="space-y-6">
          <AiBreakdownPanel incident={incident} />

          <div className="bg-ay-bg-dark2 border border-ay-border p-6">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary mb-6 flex items-center gap-2">
              <History size={14} /> Línea de tiempo
            </h3>
            <div className="space-y-6 relative before:absolute before:left-2 before:top-0 before:h-full before:w-[1px] before:bg-ay-border">
              {/* Evento 1 — siempre: reporte inicial */}
              <div className="relative pl-8">
                <div className="absolute left-0 top-1 h-4 w-4 bg-ay-primary rounded-full" />
                <p className="text-[11px] text-ay-text-secondary font-mono">
                  {formatRelativeTime(incident.createdAt)} · {formatHHMM(incident.createdAt)}
                </p>
                <p className="text-xs font-bold text-white">Reporte inicial recibido</p>
                <p className="text-[11px] text-ay-text-secondary mt-1">
                  Severidad asignada: {severityLabel[incident.severity]} · {incident.reportCount}{' '}
                  {incident.reportCount === 1 ? 'reporte' : 'reportes'} ciudadanos
                </p>
              </div>

              {/* Historial de cambios de estado — uno por entrada */}
              {incident.statusHistory.map((entry) => (
                <div key={entry.id} className="relative pl-8">
                  <div
                    className={`absolute left-0 top-1 h-4 w-4 rounded-full ${
                      entry.status === 'IN_ATTENTION'
                        ? 'bg-ay-accent'
                        : entry.status === 'CLOSED'
                          ? 'bg-ay-low'
                          : 'bg-ay-primary'
                    }`}
                  />
                  <p className="text-[11px] text-ay-text-secondary font-mono">
                    {formatRelativeTime(entry.changedAt)} · {formatHHMM(entry.changedAt)}
                  </p>
                  <p className="text-xs font-bold text-white uppercase">
                    {entry.status === 'IN_ATTENTION'
                      ? '🚓 Marcado en atención'
                      : entry.status === 'CLOSED'
                        ? '✓ Incidente cerrado'
                        : '🔄 Reactivado'}
                  </p>
                  <p className="text-[10px] text-ay-text-secondary mt-0.5">
                    Por: {entry.actorRole === 'ADMIN' ? 'Administrador' : 'Autoridad'}
                  </p>
                  {entry.feedback ? (
                    <div className="mt-2 p-3 bg-ay-bg-dark border-l-2 border-ay-accent">
                      <p className="text-[10px] font-bold uppercase tracking-wider text-ay-text-secondary mb-1">
                        Mensaje al ciudadano
                      </p>
                      <p className="text-xs text-white italic leading-relaxed">
                        "{entry.feedback}"
                      </p>
                    </div>
                  ) : (
                    <p className="text-[11px] text-ay-text-secondary mt-1 italic">
                      Sin mensaje adjunto.
                    </p>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="bg-ay-bg-dark2 border border-ay-border p-6 space-y-4">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-ay-text-secondary flex items-center justify-between">
              <span>Mensaje al ciudadano</span>
              <span className="font-mono text-ay-text-secondary normal-case">
                {feedback.length}/200
              </span>
            </h3>
            <textarea
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="Mensaje opcional para el historial (máx. 200 caracteres)"
              maxLength={200}
              rows={3}
              disabled={isClosed}
              className="w-full bg-ay-bg-dark border border-ay-border p-3 text-xs text-white outline-none focus:border-ay-primary disabled:opacity-50"
            />
            <p className="text-[10px] text-ay-text-secondary">
              Mensaje opcional al ciudadano. Se guarda en el historial junto con el cambio de estado.
            </p>
          </div>

          <div className="flex flex-col gap-2">
            <button
              disabled={isClosed || updateStatus.isPending || incident.status === 'IN_ATTENTION'}
              onClick={() => handleStatusChange('IN_ATTENTION')}
              className="bg-ay-primary text-white py-3 text-xs font-black uppercase tracking-widest disabled:opacity-50 disabled:cursor-not-allowed hover:bg-ay-primary/90 transition-all"
            >
              {updateStatus.isPending ? 'Procesando…' : 'Marcar en atención'}
            </button>
            <button
              disabled={isClosed || updateStatus.isPending}
              onClick={() => handleStatusChange('CLOSED')}
              className="bg-ay-bg-dark border border-ay-border text-ay-text-muted py-3 text-xs font-black uppercase tracking-widest hover:bg-ay-border transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cerrar incidente
            </button>
            {updateStatus.isError && (
              <p className="text-xs text-ay-critical">
                Error al actualizar:{' '}
                {updateStatus.error instanceof Error
                  ? updateStatus.error.message
                  : 'desconocido'}
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="flex justify-end pt-4">
        <p className="text-[10px] font-bold text-ay-text-secondary uppercase flex items-center gap-2">
          <CheckCircle2 size={12} /> Identidad del reportante cifrada · Solo accesible bajo orden judicial
        </p>
      </div>
    </div>
  );
}
