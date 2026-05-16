import type { AuthRepository } from '../domain/repositories/auth.repository';

export async function logoutUseCase(deps: { authRepo: AuthRepository }): Promise<void> {
  await deps.authRepo.signOut();
}
