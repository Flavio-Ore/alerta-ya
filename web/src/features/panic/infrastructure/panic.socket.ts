import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import type { Socket } from 'socket.io-client';

import { getSocket } from '../../../core/lib/socket';
import { panicKeys } from './panic.api';

/**
 * Escucha eventos panic:started / panic:stopped del backend y
 * refresca la query de sesiones activas en tiempo real.
 *
 * Montar una sola vez por página (Dashboard).
 */
export function usePanicLiveUpdates(): void {
  const qc = useQueryClient();

  useEffect(() => {
    let socket: Socket | null = null;
    let mounted = true;

    void (async () => {
      try {
        socket = await getSocket();
        if (!mounted) return;

        const invalidate = () => {
          qc.invalidateQueries({ queryKey: panicKeys.activeSessions() });
        };

        socket.on('panic:started', invalidate);
        socket.on('panic:stopped', invalidate);
      } catch {
        // Silencioso — la UI sigue con polling de fallback
      }
    })();

    return () => {
      mounted = false;
      if (socket) {
        socket.off('panic:started');
        socket.off('panic:stopped');
      }
    };
  }, [qc]);
}
