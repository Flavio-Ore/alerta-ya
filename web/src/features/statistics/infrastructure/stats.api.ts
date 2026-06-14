import { useQuery } from '@tanstack/react-query';

import { apiClient } from '../../../core/lib/axios';
import type { StatsQuery, StatsResponse } from '../../../core/api/types';

export const statsKeys = {
  all: ['stats'] as const,
  list: (q: StatsQuery) => [...statsKeys.all, q] as const,
};

function serializeQuery(query: StatsQuery): string {
  return JSON.stringify(query);
}

async function fetchStats(query: StatsQuery): Promise<StatsResponse> {
  const { data } = await apiClient.get<StatsResponse>('/stats', { params: query });
  return data;
}

export function useStats(query: StatsQuery = {}) {
  return useQuery({
    queryKey: [...statsKeys.all, serializeQuery(query)],
    queryFn: () => fetchStats(query),
    staleTime: 60_000,
  });
}
