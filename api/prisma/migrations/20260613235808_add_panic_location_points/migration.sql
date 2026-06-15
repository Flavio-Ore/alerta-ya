-- CreateTable
CREATE TABLE "panic_location_points" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "panic_location_points_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "panic_location_points_sessionId_createdAt_idx" ON "panic_location_points"("sessionId", "createdAt");

-- AddForeignKey
ALTER TABLE "panic_location_points" ADD CONSTRAINT "panic_location_points_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "panic_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
