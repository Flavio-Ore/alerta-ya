import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';

import { env } from './env';

export function initFirebase(): void {
  if (getApps().length > 0) return;

  initializeApp({
    credential: cert({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
    ...(env.FIREBASE_STORAGE_BUCKET ? { storageBucket: env.FIREBASE_STORAGE_BUCKET } : {}),
  });
}

const SIGNED_URL_TTL_MS = 5 * 60 * 1000;

/**
 * Resuelve un gs:// path a una URL HTTPS firmada (lectura, TTL 5 min).
 * Fail-open: retorna null si el bucket no está configurado, el path es inválido,
 * o la cuenta de servicio no tiene el rol signBlob/token-creator.
 */
export async function getSignedUrl(gsPath: string): Promise<string | null> {
  try {
    if (!env.FIREBASE_STORAGE_BUCKET || !gsPath.startsWith('gs://')) return null;
    const withoutPrefix = gsPath.slice('gs://'.length);
    const slashIdx = withoutPrefix.indexOf('/');
    if (slashIdx < 0) return null;
    const bucket = withoutPrefix.slice(0, slashIdx);
    const filePath = withoutPrefix.slice(slashIdx + 1);
    const [url] = await getStorage()
      .bucket(bucket)
      .file(filePath)
      .getSignedUrl({ action: 'read', expires: Date.now() + SIGNED_URL_TTL_MS });
    return url;
  } catch (err) {
    console.error('[FIREBASE] getSignedUrl failed', {
      name: err instanceof Error ? err.name : 'Unknown',
    });
    return null;
  }
}
