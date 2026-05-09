import { Storage } from '@google-cloud/storage';

import { env } from '../../../core/config/env';

const storage = new Storage({ projectId: env.GCP_PROJECT_ID });
const bucket = storage.bucket(env.GCS_BUCKET_NAME);

const SIGNED_URL_TTL_MS = 5 * 60 * 1000;

export async function generateSignedUrls(sessionId: string, count: number): Promise<string[]> {
  const urls: string[] = [];

  for (let i = 0; i < count; i++) {
    const fileName = `panic/${sessionId}/${i}.webm`;
    const file = bucket.file(fileName);

    const [url] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + SIGNED_URL_TTL_MS,
      contentType: 'audio/webm',
    });

    urls.push(url);
  }

  return urls;
}
