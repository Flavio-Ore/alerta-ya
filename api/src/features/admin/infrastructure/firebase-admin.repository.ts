import { getAuth, type UserRecord } from 'firebase-admin/auth';

export interface AdminUserDTO {
  uid: string;
  email: string;
  displayName: string | null;
  role: 'AUTHORITY' | 'ADMIN' | null;
  disabled: boolean;
  createdAt: string;
}

function toDTO(user: UserRecord): AdminUserDTO {
  const rawRole = user.customClaims?.['role'];
  const role = rawRole === 'AUTHORITY' || rawRole === 'ADMIN' ? rawRole : null;
  return {
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? null,
    role,
    disabled: user.disabled,
    createdAt: new Date(user.metadata.creationTime).toISOString(),
  };
}

export async function createFirebaseUser(
  input: { email: string; password: string; displayName: string; role: 'AUTHORITY' | 'ADMIN' },
): Promise<AdminUserDTO> {
  const user = await getAuth().createUser({
    email: input.email,
    password: input.password,
    displayName: input.displayName,
  });

  await getAuth().setCustomUserClaims(user.uid, { role: input.role });

  return toDTO(user);
}

export async function listFirebaseUsers(
  query: { search?: string; page: number; pageSize: number; role?: 'AUTHORITY' | 'ADMIN' },
): Promise<{ items: AdminUserDTO[]; total: number; page: number }> {
  const allUsers: AdminUserDTO[] = [];
  let nextPageToken: string | undefined;

  do {
    const result = await getAuth().listUsers(1000, nextPageToken);
    for (const user of result.users) {
      const dto = toDTO(user);
      if (dto.role !== null) {
        allUsers.push(dto);
      }
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  let filtered = allUsers;

  if (query.role) {
    filtered = filtered.filter((u) => u.role === query.role);
  }

  if (query.search) {
    const q = query.search.toLowerCase();
    filtered = filtered.filter(
      (u) =>
        u.email.toLowerCase().includes(q) ||
        (u.displayName ?? '').toLowerCase().includes(q),
    );
  }

  filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  const total = filtered.length;
  const start = (query.page - 1) * query.pageSize;
  const items = filtered.slice(start, start + query.pageSize);

  return { items, total, page: query.page };
}

export async function getFirebaseUser(uid: string): Promise<AdminUserDTO | null> {
  try {
    const user = await getAuth().getUser(uid);
    return toDTO(user);
  } catch {
    return null;
  }
}

export async function updateFirebaseUser(
  uid: string,
  input: { displayName?: string; role?: 'AUTHORITY' | 'ADMIN'; disabled?: boolean },
): Promise<AdminUserDTO | null> {
  const updateFields: Record<string, unknown> = {};
  if (input.displayName !== undefined) updateFields['displayName'] = input.displayName;
  if (input.disabled !== undefined) updateFields['disabled'] = input.disabled;

  if (Object.keys(updateFields).length > 0) {
    await getAuth().updateUser(uid, updateFields);
  }

  if (input.role !== undefined) {
    const user = await getAuth().getUser(uid);
    await getAuth().setCustomUserClaims(uid, { ...user.customClaims, role: input.role });
  }

  const updated = await getAuth().getUser(uid);
  return toDTO(updated);
}

export async function disableFirebaseUser(uid: string): Promise<boolean> {
  try {
    await getAuth().updateUser(uid, { disabled: true });
    return true;
  } catch {
    return false;
  }
}

export async function enableFirebaseUser(uid: string): Promise<boolean> {
  try {
    await getAuth().updateUser(uid, { disabled: false });
    return true;
  } catch {
    return false;
  }
}
