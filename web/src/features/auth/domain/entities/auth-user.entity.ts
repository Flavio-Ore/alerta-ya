export type AuthorityRole = 'AUTHORITY' | 'ADMIN';

export interface AuthUser {
  uid: string;
  email: string;
  displayName: string | null;
  role: AuthorityRole | null;
}
