import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type {
  ListIncidentsQuery,
  ListIncidentsResult,
  PublicIncidentDetailDTO,
  PublicIncidentDTO,
  UpdateStatusInput,
} from '../../../core/api/types';
import { apiClient } from '../../../core/lib/axios';

export const incidentsKeys = {
  all: ['incidents'] as const,
  lists: () => [...incidentsKeys.all, 'list'] as const,
  list: (q: ListIncidentsQuery) => [...incidentsKeys.lists(), q] as const,
  detail: (id: string) => [...incidentsKeys.all, 'detail', id] as const,
};

async function fetchIncidents(query: ListIncidentsQuery): Promise<ListIncidentsResult> {
  const { data } = await apiClient.get<ListIncidentsResult>('/incidents', { params: query });
  return data;
}

async function fetchIncidentById(id: string): Promise<PublicIncidentDetailDTO> {
  const { data } = await apiClient.get<PublicIncidentDetailDTO>(`/incidents/${id}`);
  return data;
}

async function patchIncidentStatus(id: string, input: UpdateStatusInput): Promise<PublicIncidentDTO> {
  const { data } = await apiClient.patch<PublicIncidentDTO>(`/incidents/${id}/status`, input);
  return data;
}

export function useIncidentsList(query: ListIncidentsQuery = {}) {
  return useQuery({
    queryKey: incidentsKeys.list(query),
    queryFn: () => fetchIncidents(query),
    staleTime: 15_000,
  });
}

export function useIncidentDetail(id: string | undefined) {
  return useQuery({
    queryKey: incidentsKeys.detail(id ?? ''),
    queryFn: () => fetchIncidentById(id!),
    enabled: Boolean(id),
  });
}

export function useUpdateIncidentStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id: string; input: UpdateStatusInput }) =>
      patchIncidentStatus(id, input),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: incidentsKeys.lists() });
      qc.setQueryData(incidentsKeys.detail(data.id), (prev: PublicIncidentDetailDTO | undefined) =>
        prev ? { ...prev, ...data } : prev,
      );
    },
  });
}
