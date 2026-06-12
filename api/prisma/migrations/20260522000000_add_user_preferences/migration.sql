-- AlertaYa — Migración: preferencias de usuario
-- Tabla user_preferences: alertas push y configuración de notificaciones.
-- No almacena PII — solo preferencias operativas (radio, mute).

CREATE TABLE "user_preferences" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "alertRadiusMeters" INTEGER NOT NULL DEFAULT 2000,
    "muteNotifications" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "user_preferences_userId_key" ON "user_preferences"("userId");

ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
