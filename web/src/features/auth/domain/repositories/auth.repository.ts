import type { AuthUser } from '../entities/auth-user.entity';

export interface AuthRepository {
  signIn(email: string, password: string): Promise<AuthUser>;
  signOut(): Promise<void>;
  getIdToken(forceRefresh?: boolean): Promise<string | null>;
  onAuthStateChanged(callback: (user: AuthUser | null) => void): () => void;
}
