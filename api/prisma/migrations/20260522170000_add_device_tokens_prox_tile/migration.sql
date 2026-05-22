-- AlertaYa — Migración: proxTile en device_tokens
-- Permite filtrar push FCM por área de ~330m, no solo por distrito.
-- Nullable: tokens viejos siguen funcionando hasta que el cliente envíe ubicación.

ALTER TABLE "device_tokens" ADD COLUMN "proxTile" TEXT;
CREATE INDEX "device_tokens_proxTile_idx" ON "device_tokens"("proxTile");
