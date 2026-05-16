-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'INCIDENT_STATUS_UPDATE';

-- AlterTable
ALTER TABLE "incidents" ADD COLUMN     "feedback" TEXT;
