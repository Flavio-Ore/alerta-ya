import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type {
  AdminUserDTO,
  CreateAdminUserInput,
  ListAdminUsersResult,
  UpdateAdminUserInput,
} from '../../../core/api/types';
import { apiClient } from '../../../core/lib/axios';

export const adminKeys = {
  all: ['admin'] as const,
  users: () => [...adminKeys.all, 'users'] as const,
  user: (uid: string) => [...adminKeys.users(), uid] as const,
};

async function fetchUsers(query: {
  search?: string;
  page?: number;
  pageSize?: number;
  role?: 'AUTHORITY' | 'ADMIN';
}): Promise<ListAdminUsersResult> {
  const { data } = await apiClient.get<ListAdminUsersResult>('/admin/users', { params: query });
  return data;
}

async function createUser(input: CreateAdminUserInput): Promise<AdminUserDTO> {
  const { data } = await apiClient.post<AdminUserDTO>('/admin/users', input);
  return data;
}

async function updateUser(uid: string, input: UpdateAdminUserInput): Promise<AdminUserDTO> {
  const { data } = await apiClient.patch<AdminUserDTO>(`/admin/users/${uid}`, input);
  return data;
}

async function disableUser(uid: string): Promise<void> {
  await apiClient.delete(`/admin/users/${uid}/disable`);
}

async function enableUser(uid: string): Promise<void> {
  await apiClient.post(`/admin/users/${uid}/enable`);
}

export function useAdminUsersList(query: {
  search?: string;
  page?: number;
  pageSize?: number;
  role?: 'AUTHORITY' | 'ADMIN';
} = {}) {
  return useQuery({
    queryKey: [...adminKeys.users(), query],
    queryFn: () => fetchUsers(query),
    staleTime: 30_000,
  });
}

export function useCreateAdminUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateAdminUserInput) => createUser(input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: adminKeys.users() });
    },
  });
}

export function useUpdateAdminUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ uid, input }: { uid: string; input: UpdateAdminUserInput }) => updateUser(uid, input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: adminKeys.users() });
    },
  });
}

export function useDisableAdminUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (uid: string) => disableUser(uid),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: adminKeys.users() });
    },
  });
}

export function useEnableAdminUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (uid: string) => enableUser(uid),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: adminKeys.users() });
    },
  });
}
