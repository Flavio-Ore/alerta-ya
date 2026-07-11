import { PanicSession, PanicStatus } from '@prisma/client';

export type { PanicStatus };

export interface PublicPanicSessionDTO {
  id: string;
  startedAt: string;
  endedAt?: string | null;
  lat: number;
  lng: number;
  status: PanicStatus;
}

export function toPanicDTO(session: PanicSession): PublicPanicSessionDTO {
  return {
    id: session.id,
    startedAt: session.startedAt.toISOString(),
    endedAt: session.endedAt?.toISOString(),
    lat: session.lat,
    lng: session.lng,
    status: session.status,
  };
}

export interface PanicSessionSummaryDTO {
  id: string;
  lat: number;
  lng: number;
  startedAt: string;
  endedAt: string | null;
  status: PanicStatus;
  deactivatedBy: string | null;
  recordingBlocksCount: number;
}

export function toPanicSummaryDTO(
  session: PanicSession & { _count: { recordingBlocks: number } },
): PanicSessionSummaryDTO {
  return {
    id: session.id,
    lat: session.lat,
    lng: session.lng,
    startedAt: session.startedAt.toISOString(),
    endedAt: session.endedAt?.toISOString() ?? null,
    status: session.status,
    deactivatedBy: session.deactivatedBy,
    recordingBlocksCount: session._count.recordingBlocks,
  };
}
