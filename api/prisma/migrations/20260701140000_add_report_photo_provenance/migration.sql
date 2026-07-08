-- AddColumn: photo provenance fields to reports (additive, nullable — no breaking change)
-- Mirrors the "incidents" columns added in 20260619160000_add_evidence_fields, but per-report:
-- today only the first report of an incident is ML-evaluated, so these columns let
-- per-report provenance be stored/threaded independently of the incident it links to.
ALTER TABLE "reports"
    ADD COLUMN "photoTakenAt" TIMESTAMP(3),
    ADD COLUMN "photoSource"  TEXT;

-- Down migration (manual rollback):
-- ALTER TABLE "reports" DROP COLUMN "photoTakenAt", DROP COLUMN "photoSource";
