-- AlertaYa — Migración: panic prefs en user_preferences
-- Agrega panicRecordAudio y panicAlarmSound. GPS NO se incluye — siempre activo por diseño.

ALTER TABLE "user_preferences"
  ADD COLUMN "panicRecordAudio" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN "panicAlarmSound" BOOLEAN NOT NULL DEFAULT true;
