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

  // Google Cloud Storage
  GCS_BUCKET_NAME: z.string(),
  GCP_PROJECT_ID: z.string(),

  // CORS
  WEB_URL: z.string().url().default('http://localhost:5173'),

  // ML service
  ML_SERVICE_URL: z.string().url().default('http://localhost:8000'),

  // JWT
  JWT_SECRET: z.string().min(32),

  // Jobs — secret que Cloud Scheduler manda en X-Job-Secret
  JOB_SECRET: z.string().min(16).default('dev-job-secret-change-in-prod'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variables de entorno inválidas:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
