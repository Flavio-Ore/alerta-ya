import { useQuery } from '@tanstack/react-query';

import { apiClient } from '../../../core/lib/axios';
import type { PanicSessionDTO } from '../../../core/api/types';

export const panicKeys = {
  activeSessions: () => ['panic', 'active'] as const,
};

async function fetchActivePanicSessions(): Promise<PanicSessionDTO[]> {
  const { data } = await apiClient.get<PanicSessionDTO[]>('/panic/sessions/active');
  return data;
}

/**
 * Sesiones de pánico activas — usadas por el panel de autoridades.
 * Polling de fallback cada 30 s en caso de que el WebSocket pierda conexión.
 */
export function useActivePanicSessions() {
  return useQuery({
    queryKey: panicKeys.activeSessions(),
    queryFn:  fetchActivePanicSessions,
    refetchInterval: 30_000,
    staleTime:       10_000,
  });
}
