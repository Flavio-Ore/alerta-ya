export interface StoreEscrowKeyData {
  panicSessionId: string;
  wrappedKey: Buffer;
  kmsKeyVersion: string;
  algorithm: string;
}

export interface StoredEscrowKey {
  wrappedKey: Buffer;
  kmsKeyVersion: string;
}

export interface EscrowKeyRepository {
  create(data: StoreEscrowKeyData): Promise<void>;
  findBySessionId(panicSessionId: string): Promise<StoredEscrowKey | null>;
}
