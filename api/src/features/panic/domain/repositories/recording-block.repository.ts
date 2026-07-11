export interface RecordingBlockData {
  panicSessionId: string;
  blockIndex: number;
  storagePath: string;
}

export interface StoredRecordingBlock {
  blockIndex: number;
  storagePath: string;
}

export interface RecordingBlockRepository {
  upsert(data: RecordingBlockData): Promise<void>;
  findBySessionId(panicSessionId: string): Promise<StoredRecordingBlock[]>;
}
