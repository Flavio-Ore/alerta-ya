import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface UpdatePanicLocationInput {
  sessionId: string;
  uid: string;
  lat: number;
  lng: number;
}

export interface UpdatePanicLocationDeps {
  panicRepo: PanicSessionRepository;
  getUserId: (uid: string) => Promise<string>;
}

export async function updatePanicLocation(
  input: UpdatePanicLocationInput,
  deps: UpdatePanicLocationDeps,
): Promise<void> {
  const session = await deps.panicRepo.findById(input.sessionId);
  if (!session) {
    throw new AppError(404, 'Sesión de pánico no encontrada');
  }

  const userId = await deps.getUserId(input.uid);
  if (session.userId !== userId) {
    throw new AppError(403, 'No tenés acceso a esta sesión');
  }

  if (session.status !== 'ACTIVE') {
    return; // Sesión ya cerrada — descartar silenciosamente
  }

  await deps.panicRepo.addLocationPoint(input.sessionId, input.lat, input.lng);
}
