import { PanicSession, PanicStatus } from '@prisma/client';
import { CloudinaryUploadParams } from '../../infrastructure/cloudinary.client';

export type { PanicStatus };

export interface PublicPanicSessionDTO {
  id: string;
  startedAt: string;
  endedAt?: string | null;
  lat: number;
  lng: number;
  status: PanicStatus;
  /** Parámetros para upload directo a Cloudinary desde el cliente. */
  uploadParams: CloudinaryUploadParams[];
}

export function toPanicDTO(
  session: PanicSession,
  uploadParams: CloudinaryUploadParams[],
): PublicPanicSessionDTO {
  return {
    id: session.id,
    startedAt: session.startedAt.toISOString(),
    endedAt: session.endedAt?.toISOString(),
    lat: session.lat,
    lng: session.lng,
    status: session.status,
    uploadParams,
  };
}
