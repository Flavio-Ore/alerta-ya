import { PanicSession } from '@prisma/client';

export interface CreatePanicSessionData {
  userId: string;
  lat: number;
  lng: number;
}

export interface PanicSessionRepository {
  create(data: CreatePanicSessionData): Promise<PanicSession>;
  findActiveByUser(userId: string): Promise<PanicSession | null>;
  findAllActive(): Promise<PanicSession[]>;
  deactivate(id: string, method: 'pin' | 'timeout'): Promise<PanicSession>;
  appendRecordingUrl(id: string, url: string): Promise<void>;
  findById(id: string): Promise<PanicSession | null>;
  addLocationPoint(sessionId: string, lat: number, lng: number): Promise<void>;
}
