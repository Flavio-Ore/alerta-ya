import { create } from 'zustand';
import { loginUseCase } from '../../application/login.usecase';
import { logoutUseCase } from '../../application/logout.usecase';
import type { AuthUser } from '../../domain/entities/auth-user.entity';
import { firebaseAuthRepository } from '../../infrastructure/firebase-auth.repository';

interface AuthState {
  user: AuthUser | null;
  isReady: boolean;
  isAuthenticating: boolean;
  error: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  bootstrap: () => () => void;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isReady: false,
  isAuthenticating: false,
  error: null,

  signIn: async (email, password) => {
    set({ isAuthenticating: true, error: null });
    try {
      const user = await loginUseCase({ email, password }, { authRepo: firebaseAuthRepository });
      set({ user, isAuthenticating: false });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al iniciar sesión';
      set({ isAuthenticating: false, error: message });
      throw err;
    }
  },

  signOut: async () => {
    await logoutUseCase({ authRepo: firebaseAuthRepository });
    set({ user: null });
  },

  bootstrap: () => {
    return firebaseAuthRepository.onAuthStateChanged((user) => {
      set({ user, isReady: true });
    });
  },

  clearError: () => set({ error: null }),
}));
