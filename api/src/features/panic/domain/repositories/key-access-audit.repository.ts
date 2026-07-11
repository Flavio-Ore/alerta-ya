export type KeyAccessResult = 'SUCCESS' | 'DENIED' | 'ERROR';

export interface KeyAccessAuditData {
  panicSessionId: string;
  requestedById: string;
  ipAddress: string | null;
  result: KeyAccessResult;
}

export interface KeyAccessAuditRepository {
  create(data: KeyAccessAuditData): Promise<void>;
}
