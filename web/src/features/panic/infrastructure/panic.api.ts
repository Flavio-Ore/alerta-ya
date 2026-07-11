import { useMutation, useQuery } from '@tanstack/react-query';
import type {
  ListPanicSessionsQuery,
  ListPanicSessionsResult,
  PanicSessionDTO,
  PanicSessionSummaryDTO,
  ReleaseRecordingKeyResult,
} from '../../../core/api/types';
import { apiClient } from '../../../core/lib/axios';

export const panicKeys = {
  all: ['panic'] as const,
  activeSessions: () => ['panic', 'active'] as const,
  list: (q: ListPanicSessionsQuery) => ['panic', 'list', q] as const,
  detail: (id: string) => ['panic', 'detail', id] as const,
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
    queryFn: fetchActivePanicSessions,
    refetchInterval: 30_000,
    staleTime: 10_000,
  });
}

async function fetchPanicSessions(query: ListPanicSessionsQuery): Promise<ListPanicSessionsResult> {
  const { data } = await apiClient.get<ListPanicSessionsResult>('/panic/sessions', { params: query });
  return data;
}

/**
 * Listado paginado de sesiones de pánico (activas + históricas) para el panel
 * "Pánico" del sidebar. A diferencia de useActivePanicSessions, no hace polling:
 * es una pantalla de consulta/auditoría, no de monitoreo en vivo.
 */
export function usePanicSessionsList(query: ListPanicSessionsQuery = {}) {
  return useQuery({
    queryKey: panicKeys.list(query),
    queryFn: () => fetchPanicSessions(query),
    staleTime: 15_000,
  });
}

async function fetchPanicSessionById(id: string): Promise<PanicSessionSummaryDTO> {
  const { data } = await apiClient.get<PanicSessionSummaryDTO>(`/panic/sessions/${id}`);
  return data;
}

/**
 * Sesión de pánico individual — usada como fallback en la página de detalle
 * cuando no llegó por navegación desde la lista (ej. recarga de página o
 * deep-link), evitando escanear el listado paginado buscando el id.
 */
export function usePanicSessionDetail(id: string | undefined) {
  return useQuery({
    queryKey: panicKeys.detail(id ?? ''),
    queryFn: () => fetchPanicSessionById(id!),
    enabled: Boolean(id),
  });
}

async function releaseRecordingKey(sessionId: string): Promise<ReleaseRecordingKeyResult> {
  const { data } = await apiClient.post<ReleaseRecordingKeyResult>(
    `/panic/sessions/${sessionId}/recordings/access`,
  );
  return data;
}

/**
 * Pide la clave AES + URLs firmadas de los bloques de audio. Es una mutation,
 * NUNCA un useQuery: el resultado (incluye aesKey) no debe persistir en el
 * cache de TanStack Query ni refetchearse en background.
 */
export function useReleaseRecordingKey() {
  return useMutation({
    mutationFn: releaseRecordingKey,
  });
}
