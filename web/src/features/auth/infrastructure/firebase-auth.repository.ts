import {
  onAuthStateChanged as firebaseOnAuthStateChanged,
  signOut as firebaseSignOut,
  signInWithEmailAndPassword,
  type User as FirebaseUser,
} from 'firebase/auth';
import { firebaseAuth, firebaseAvailable } from '../../../core/firebase/client';
import type { AuthUser, AuthorityRole } from '../domain/entities/auth-user.entity';
import type { AuthRepository } from '../domain/repositories/auth.repository';

const KNOWN_ROLES: readonly AuthorityRole[] = ['AUTHORITY', 'ADMIN'];

function requireAuth() {
  if (!firebaseAuth || !firebaseAvailable) {
    throw new Error(
      'Firebase no está configurado. Completá web/.env con las credenciales del proyecto Firebase.',
    );
  }
  return firebaseAuth;
}

async function mapFirebaseUser(user: FirebaseUser, forceRefresh = false): Promise<AuthUser> {
  // forceRefresh garantiza que custom claims recién seteados se reflejen en el token
  const tokenResult = await user.getIdTokenResult(forceRefresh);
  const claimRole = tokenResult.claims['role'];
  const role = typeof claimRole === 'string' && KNOWN_ROLES.includes(claimRole as AuthorityRole)
    ? (claimRole as AuthorityRole)
    : null;

  return {
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    role,
  };
}

export class FirebaseAuthRepository implements AuthRepository {
  async signIn(email: string, password: string): Promise<AuthUser> {
    const auth = requireAuth();
    const credential = await signInWithEmailAndPassword(auth, email, password);
    // forceRefresh=true: pide un token fresco al servidor para recoger custom claims
    // seteados desde Admin SDK (scripts/set-role.ts) sin necesidad de re-login
    return mapFirebaseUser(credential.user, true);
  }

  async signOut(): Promise<void> {
    if (!firebaseAuth) return;
    await firebaseSignOut(firebaseAuth);
  }

  async getIdToken(forceRefresh = false): Promise<string | null> {
    if (!firebaseAuth) return null;
    const user = firebaseAuth.currentUser;
    if (!user) return null;
    return user.getIdToken(forceRefresh);
  }

  onAuthStateChanged(callback: (user: AuthUser | null) => void): () => void {
    if (!firebaseAuth) {
      // Sin Firebase configurado, reportamos "sin usuario" para que isReady=true y la UI renderice
      callback(null);
      return () => { };
    }
    return firebaseOnAuthStateChanged(firebaseAuth, async (firebaseUser) => {
      if (!firebaseUser) {
        callback(null);
        return;
      }
      const mapped = await mapFirebaseUser(firebaseUser);
      callback(mapped);
    });
  }
}

export const firebaseAuthRepository = new FirebaseAuthRepository();
