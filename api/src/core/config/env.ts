import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),

  // Base de datos
  DATABASE_URL: z.string().url(),

  // Redis
  REDIS_URL: z.string().default('redis://localhost:6379'),

  // Firebase Admin
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().email().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),

  // Google Cloud Storage
  GCS_BUCKET_NAME: z.string().optional(),
  GCP_PROJECT_ID: z.string().optional(),

  // Cloud KMS — escrow de claves de cifrado de grabaciones de pánico
  KMS_PROJECT_ID: z.string().optional(),
  KMS_LOCATION_ID: z.string().default('global'),
  KMS_KEY_RING_ID: z.string().default('panic-escrow'),
  KMS_KEY_ID: z.string().default('panic-escrow-key'),
  KMS_KEY_VERSION: z.string().default('1'),

  // CORS
  WEB_URL: z.string().url().default('http://localhost:5173'),

  // ML service
  ML_SERVICE_URL: z.string().url().default('http://localhost:8000'),

  // JWT
  JWT_SECRET: z.string().min(32),

  // Jobs — secret que Cloud Scheduler manda en X-Job-Secret
  JOB_SECRET: z.string().min(16).default('dev-job-secret-change-in-prod'),

  // GLM (Zhipu) — asistente IA de redacción de mensajes para autoridades.
  // Opcional: sin key, el endpoint /suggest-message responde 503 (la web oculta el botón).
  GLM_API_KEY: z.string().optional(),
  // Provider: Z.AI (api.z.ai). La key del proyecto es de Z.AI — el endpoint de
  // Zhipu bigmodel.cn la rechaza (400). Base: https://api.z.ai/api/paas/v4.
  GLM_API_URL: z.string().url().default('https://api.z.ai/api/paas/v4/chat/completions'),
  // Modelo de Z.AI (glm-4-flash es de bigmodel.cn, no existe en z.ai → 400).
  GLM_MODEL: z.string().default('glm-4.7'),
  GLM_TIMEOUT_MS: z.coerce.number().int().min(1000).default(60000),

  // GLM Vision — verificación de relevancia visual de evidencia fotográfica.
  // Opcional: sin configurar, el multiplicador de visión queda en 1.0 (sin efecto).
  GLM_VISION_MODEL: z.string().default('glm-4v-flash'),
  GLM_VISION_TIMEOUT_MS: z.coerce.number().int().min(1000).default(3000),

  // Firebase Storage — bucket para acceso a imágenes firmadas (gs:// → HTTPS 5-min TTL).
  // Opcional: sin configurar, la verificación visual se omite (fail-open).
  FIREBASE_STORAGE_BUCKET: z.string().default(''),

  // Multiplicador de visión — ajuste de peso del signal visual sobre el score ML.
  // 0.0 = sin efecto (desactivado), 0.2 = efecto moderado (default).
  VISION_SCORE_K: z.coerce.number().default(0.2),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variables de entorno inválidas:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
