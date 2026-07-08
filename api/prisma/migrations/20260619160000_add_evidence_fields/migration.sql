-- AddColumn: evidence timestamp fields to incidents (additive, nullable — no breaking change)
ALTER TABLE "incidents"
    ADD COLUMN "photoTakenAt" TIMESTAMP(3),
    ADD COLUMN "photoSource"  TEXT;

-- Down migration (manual rollback):
-- ALTER TABLE "incidents" DROP COLUMN "photoTakenAt", DROP COLUMN "photoSource";
