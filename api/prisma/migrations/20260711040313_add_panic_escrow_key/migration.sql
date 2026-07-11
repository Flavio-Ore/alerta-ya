-- CreateTable
CREATE TABLE "panic_session_keys" (
    "id" TEXT NOT NULL,
    "panicSessionId" TEXT NOT NULL,
    "wrappedKey" BYTEA NOT NULL,
    "kmsKeyName" TEXT NOT NULL,
    "kmsKeyVersion" TEXT NOT NULL,
    "algorithm" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "panic_session_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recording_blocks" (
    "id" TEXT NOT NULL,
    "panicSessionId" TEXT NOT NULL,
    "blockIndex" INTEGER NOT NULL,
    "storagePath" TEXT NOT NULL,
    "uploadedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_blocks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "key_access_audits" (
    "id" TEXT NOT NULL,
    "panicSessionId" TEXT NOT NULL,
    "requestedById" TEXT NOT NULL,
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ipAddress" TEXT,
    "result" TEXT NOT NULL,

    CONSTRAINT "key_access_audits_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "panic_session_keys_panicSessionId_key" ON "panic_session_keys"("panicSessionId");

-- CreateIndex
CREATE UNIQUE INDEX "recording_blocks_panicSessionId_blockIndex_key" ON "recording_blocks"("panicSessionId", "blockIndex");

-- CreateIndex
CREATE INDEX "key_access_audits_panicSessionId_requestedAt_idx" ON "key_access_audits"("panicSessionId", "requestedAt");

-- AddForeignKey
ALTER TABLE "panic_session_keys" ADD CONSTRAINT "panic_session_keys_panicSessionId_fkey" FOREIGN KEY ("panicSessionId") REFERENCES "panic_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recording_blocks" ADD CONSTRAINT "recording_blocks_panicSessionId_fkey" FOREIGN KEY ("panicSessionId") REFERENCES "panic_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
