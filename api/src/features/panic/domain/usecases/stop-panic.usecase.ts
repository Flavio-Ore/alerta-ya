import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { PublicPanicSessionDTO, toPanicDTO } from '../entities/panic-session.entity';
import { AppError } from '../../../../core/errors/AppError';
import { UserLookupService } from '../../../incidents/infrastructure/user-lookup.service';

export interface StopPanicInput {
  sessionId: string;
  uid: string;
}

export interface StopPanicDeps {
  panicRepo: PanicSessionRepository;
  userLookup: UserLookupService;
}

export async function stopPanic(
  input: StopPanicInput,
  deps: StopPanicDeps,
): Promise<PublicPanicSessionDTO> {
  const session = await deps.panicRepo.findById(input.sessionId);
  if (!session) throw new AppError(404, 'Sesión de pánico no encontrada');
  if (session.status !== 'ACTIVE') throw new AppError(409, 'La sesión ya fue desactivada');

  // Verificar propiedad — nunca aceptar userId del body
  const user = await deps.userLookup.findOrCreate(input.uid);
  if (session.userId !== user.id) {
    throw new AppError(403, 'No tenés permiso para desactivar esta sesión');
  }

  const updated = await deps.panicRepo.deactivate(input.sessionId, 'pin');
  return toPanicDTO(updated, []);
}
