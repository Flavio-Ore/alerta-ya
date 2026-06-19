import { useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';
import type { Socket } from 'socket.io-client';
import type { PublicIncidentDTO } from '../../../core/api/types';
import { signalRefresh } from '../../../core/lib/refresh-signal';
import { getSocket } from '../../../core/lib/socket';
import { useToast } from '../../../hooks/use-toast';
import { incidentTypeLabel } from '../presentation/utils/labels';
import { incidentsKeys } from './incidents.api';

/**
 * Hook que escucha eventos en vivo del backend (incident:new, incident:updated)
 * y invalida las queries de TanStack para que se re-fetchen.
 *
 * HU008 H8-8: toasts en tiempo real para incidentes CRÍTICOS.
 *
 * Montar una sola vez por pantalla (Dashboard, IncidentsList).
 */
export function useIncidentLiveUpdates(): void {
  const qc = useQueryClient();
  const { toast } = useToast();

  useEffect(() => {
    let socket: Socket | null = null;
    let mounted = true;

    void (async () => {
      try {
        socket = await getSocket();
        if (!mounted) return;

        const onNew = (incident: PublicIncidentDTO) => {
          signalRefresh();
          qc.invalidateQueries({ queryKey: incidentsKeys.lists() });

          // HU008 H8-8: toast SOLO para incidentes críticos
          if (incident.severity === 'CRITICAL') {
            toast({
              title: `🚨 ${incidentTypeLabel[incident.type]}`,
              description: `${incident.district} · ${incident.reportCount} reportes`,
              variant: 'destructive',
            });
          }
        };

        const onUpdated = (incident: PublicIncidentDTO) => {
          signalRefresh();
          qc.invalidateQueries({ queryKey: incidentsKeys.lists() });
          qc.invalidateQueries({ queryKey: incidentsKeys.detail(incident.id) });
        };

        socket.on('incident:new', onNew);
        socket.on('incident:updated', onUpdated);
      } catch {
        // Silencioso — si falla la conexión, la UI sigue funcionando con polling
      }
    })();

    return () => {
      mounted = false;
      if (socket) {
        socket.off('incident:new');
        socket.off('incident:updated');
      }
    };
  }, [qc, toast]);
}
