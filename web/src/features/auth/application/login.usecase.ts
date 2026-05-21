import type { AuthUser } from '../domain/entities/auth-user.entity';
import type { AuthRepository } from '../domain/repositories/auth.repository';

export class UnauthorizedRoleError extends Error {
  constructor() {
    super('El usuario no tiene permisos para acceder al panel de autoridades');
    this.name = 'UnauthorizedRoleError';
  }
}

export interface LoginInput {
  email: string;
  password: string;
}

export async function loginUseCase(
  input: LoginInput,
  deps: { authRepo: AuthRepository },
): Promise<AuthUser> {
  const user = await deps.authRepo.signIn(input.email, input.password);

  if (user.role !== 'AUTHORITY' && user.role !== 'ADMIN') {
    await deps.authRepo.signOut();
    throw new UnauthorizedRoleError();
  }

  return user;
}
