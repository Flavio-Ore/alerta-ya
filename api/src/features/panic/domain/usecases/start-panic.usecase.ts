import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { PublicPanicSessionDTO, toPanicDTO } from '../entities/panic-session.entity';
import { UploadParams } from '../entities/upload-params.entity';
import { AppError } from '../../../../core/errors/AppError';

const UPLOAD_SLOTS = 6; // 6 bloques de 10 min = 60 min máximo

export interface StartPanicInput {
  userId: string;
  lat: number;
  lng: number;
}

export interface StartPanicDeps {
  panicRepo: PanicSessionRepository;
  generateUploadParams: (sessionId: string, count: number) => UploadParams[];
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

  const uploadParams = deps.generateUploadParams(session.id, UPLOAD_SLOTS);

  return toPanicDTO(session, uploadParams);
}
