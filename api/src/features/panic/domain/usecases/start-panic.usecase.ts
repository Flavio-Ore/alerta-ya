import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { PublicPanicSessionDTO, toPanicDTO } from '../entities/panic-session.entity';
import { AppError } from '../../../../core/errors/AppError';

export interface StartPanicInput {
  userId: string;
  lat: number;
  lng: number;
}

export interface StartPanicDeps {
  panicRepo: PanicSessionRepository;
}

export async function startPanic(
  input: StartPanicInput,
  deps: StartPanicDeps,
): Promise<PublicPanicSessionDTO> {
  const existing = await deps.panicRepo.findActiveByUser(input.userId);
  if (existing) {
    throw new AppError(409, 'Ya tenés una sesión de pánico activa');
  }

  const session = await deps.panicRepo.create({
    userId: input.userId,
    lat: input.lat,
    lng: input.lng,
  });

  return toPanicDTO(session);
}
