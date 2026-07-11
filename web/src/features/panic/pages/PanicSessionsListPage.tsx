import { useState } from 'react';
import { useNavigate } from '@tanstack/react-router';
import { Headphones } from 'lucide-react';

import { usePanicSessionsList } from '../infrastructure/panic.api';
import { usePanicLiveUpdates } from '../infrastructure/panic.socket';
import { formatRelativeTime, formatHHMM } from '../../incidents/presentation/utils/labels';
import type { PanicSessionStatus, PanicSessionSummaryDTO } from '../../../core/api/types';

const STATUS_OPTIONS: (PanicSessionStatus | 'ALL')[] = ['ALL', 'ACTIVE', 'DEACTIVATED', 'TIMEOUT'];

const STATUS_LABEL: Record<PanicSessionStatus | 'ALL', string> = {
  ALL: 'Todos',
  ACTIVE: 'Activo',
  DEACTIVATED: 'Desactivado',
  TIMEOUT: 'Expirado',
};

const STATUS_PILL: Record<PanicSessionStatus, string> = {
  ACTIVE: 'bg-ay-critical/10 text-ay-critical border-ay-critical/30',
  DEACTIVATED: 'bg-ay-low/10 text-ay-low border-ay-low/30',
  TIMEOUT: 'bg-ay-text-secondary/10 text-ay-text-secondary border-ay-text-secondary/30',
};

const PAGE_SIZE = 20;

export default function PanicSessionsListPage() {
  usePanicLiveUpdates();
  const navigate = useNavigate();

  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<PanicSessionStatus | 'ALL'>('ALL');

  const query = {
    page,
    pageSize: PAGE_SIZE,
    ...(statusFilter !== 'ALL' && { status: statusFilter }),
  };
  const { data, isLoading, isError } = usePanicSessionsList(query);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;
  const items = data?.items ?? [];

  return (
    <div className="flex-1 flex flex-col overflow-hidden bg-ay-bg-dark">
      <header className="flex items-center justify-between flex-wrap gap-3 px-4 md:px-10 py-4 md:py-8">
        <div className="flex flex-col gap-1">
          <h2 className="text-2xl font-bold text-white font-headline tracking-tight">Pánico</h2>
          <p className="text-sm text-ay-text-secondary font-medium">
            {data?.total ?? '—'} sesiones registradas
          </p>
        </div>
      </header>

      <section className="px-4 md:px-10 mb-4 flex items-center gap-1.5">
        {STATUS_OPTIONS.map((opt) => (
          <button
            key={opt}
            onClick={() => {
              setStatusFilter(opt);
              setPage(1);
            }}
            className={`text-xs font-bold px-3 py-1.5 rounded-md border transition-all uppercase tracking-wider ${
              statusFilter === opt
                ? 'bg-ay-primary text-white border-ay-primary'
                : 'border-ay-border text-ay-text-secondary hover:text-white hover:border-white'
            }`}
          >
            {STATUS_LABEL[opt]}
          </button>
        ))}
      </section>

      <section className="flex-1 px-4 md:px-10 overflow-hidden flex flex-col min-h-0">
        <div className="flex-1 overflow-auto rounded-xl border border-ay-border/30 bg-ay-bg-dark2/30">
          <table className="w-full text-left border-collapse">
            <thead className="sticky top-0 bg-ay-bg-dark2 z-10">
              <tr>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">Inicio</th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">Estado</th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">Ubicación</th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline">Grabación</th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-outline text-right">Acción</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ay-border/20">
              {isLoading && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-ay-text-secondary text-sm">
                    Cargando sesiones…
                  </td>
                </tr>
              )}
              {isError && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-ay-critical text-sm">
                    Error al cargar sesiones de pánico.
                  </td>
                </tr>
              )}
              {!isLoading && !isError && items.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-ay-text-secondary text-sm">
                    No hay sesiones de pánico con los filtros aplicados.
                  </td>
                </tr>
              )}
              {items.map((session, idx) => (
                <tr
                  key={session.id}
                  className={`hover:bg-stitch-surface-container-highest/20 transition-colors ${idx % 2 === 0 ? 'bg-ay-bg-dark/50' : ''}`}
                >
                  <td className="px-6 py-4 text-sm text-white">
                    {formatRelativeTime(session.startedAt)} · {formatHHMM(session.startedAt)}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase border ${STATUS_PILL[session.status]}`}>
                      {STATUS_LABEL[session.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-outline font-mono">
                    {session.lat.toFixed(4)}, {session.lng.toFixed(4)}
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-outline">
                    {session.recordingBlocksCount > 0 ? (
                      <span className="flex items-center gap-1.5">
                        <Headphones size={13} /> {session.recordingBlocksCount} bloques
                      </span>
                    ) : (
                      'Sin grabación'
                    )}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button
                      onClick={() => {
                        const state: { session: PanicSessionSummaryDTO } = { session };
                        navigate({
                          to: '/panic/$sessionId',
                          params: { sessionId: session.id },
                          state,
                        });
                      }}
                      className="text-xs font-bold text-stitch-primary hover:text-white transition-colors tracking-wider"
                    >
                      VER DETALLE
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="py-6 flex justify-center">
          <nav className="flex items-center gap-4 text-xs text-ay-text-secondary font-medium">
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              ← Anterior
            </button>
            <span className="text-white">Página {page} de {totalPages}</span>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              Siguiente →
            </button>
          </nav>
        </div>
      </section>
    </div>
  );
}
