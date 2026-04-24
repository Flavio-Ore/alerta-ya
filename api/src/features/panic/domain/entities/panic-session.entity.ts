import { PanicSession, PanicStatus } from '@prisma/client';

export type { PanicStatus };

export interface PublicPanicSessionDTO {
  id: string;
  startedAt: string;
  endedAt?: string | null;
  lat: number;
  lng: number;
  status: PanicStatus;
  uploadUrls?: string[];
}

export function toPanicDTO(session: PanicSession, uploadUrls?: string[]): PublicPanicSessionDTO {
  return {
    id: session.id,
    startedAt: session.startedAt.toISOString(),
    endedAt: session.endedAt?.toISOString(),
    lat: session.lat,
    lng: session.lng,
    status: session.status,
    uploadUrls,
  };
}
