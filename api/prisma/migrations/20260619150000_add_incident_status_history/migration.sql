-- CreateTable
CREATE TABLE "incident_status_history" (
    "id"         TEXT NOT NULL,
    "incidentId" TEXT NOT NULL,
    "status"     "IncidentStatus" NOT NULL,
    "feedback"   TEXT,
    "actorUid"   TEXT NOT NULL,
    "actorRole"  TEXT NOT NULL,
    "changedAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "incident_status_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "incident_status_history_incidentId_changedAt_idx"
    ON "incident_status_history"("incidentId", "changedAt");

-- AddForeignKey
ALTER TABLE "incident_status_history"
    ADD CONSTRAINT "incident_status_history_incidentId_fkey"
    FOREIGN KEY ("incidentId") REFERENCES "incidents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
