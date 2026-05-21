import { Storage } from '@google-cloud/storage';

import { env } from '../../../core/config/env';

const storage = new Storage({ projectId: env.GCP_PROJECT_ID });
const bucket = storage.bucket(env.GCS_BUCKET_NAME);

// 70 min cubre el peor caso: bloque 6 completa a t=60min y debe subirse antes de expirar
const SIGNED_URL_TTL_MS = 70 * 60 * 1000;

export async function generateSignedUrls(sessionId: string, count: number): Promise<string[]> {
  const urls: string[] = [];

  for (let i = 0; i < count; i++) {
    const fileName = `panic/${sessionId}/${i}.bin`;
    const file = bucket.file(fileName);

    const [url] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + SIGNED_URL_TTL_MS,
      contentType: 'application/octet-stream',
    });

    urls.push(url);
  }

  return urls;
}
