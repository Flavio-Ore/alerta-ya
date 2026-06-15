import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),

  // Base de datos
  DATABASE_URL: z.string().url(),

  // Redis
  REDIS_URL: z.string().default('redis://localhost:6379'),

  // Firebase Admin
  FIREBASE_PROJECT_ID: z.string(),
  FIREBASE_CLIENT_EMAIL: z.string().email(),
  FIREBASE_PRIVATE_KEY: z.string(),

  // Google Cloud Storage — no usado en MVP, Cloudinary reemplaza para grabaciones de pánico
  GCS_BUCKET_NAME: z.string().optional(),
  GCP_PROJECT_ID: z.string().optional(),

  // CORS
  WEB_URL: z.string().url().default('http://localhost:5173'),

  // ML service
  ML_SERVICE_URL: z.string().url().default('http://localhost:8000'),

  // JWT
  JWT_SECRET: z.string().min(32),

  // Jobs — secret que Cloud Scheduler manda en X-Job-Secret
  JOB_SECRET: z.string().min(16).default('dev-job-secret-change-in-prod'),

  // Cloudinary — evidencia de imágenes/videos en reportes
  CLOUDINARY_CLOUD_NAME: z.string(),
  CLOUDINARY_API_KEY: z.string(),
  CLOUDINARY_API_SECRET: z.string(),
  CLOUDINARY_UPLOAD_PRESET: z.string().default('alertaya_evidence'),

  // GLM (Zhipu) — asistente IA de redacción de mensajes para autoridades.
  // Opcional: sin key, el endpoint /suggest-message responde 503 (la web oculta el botón).
  GLM_API_KEY: z.string().optional(),
  GLM_API_URL: z.string().url().default('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
  GLM_MODEL: z.string().default('glm-4-flash'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variables de entorno inválidas:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
