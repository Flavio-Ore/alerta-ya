import { v2 as cloudinary } from 'cloudinary';

import { env } from '../../../core/config/env';

cloudinary.config({
  cloud_name: env.CLOUDINARY_CLOUD_NAME,
  api_key: env.CLOUDINARY_API_KEY,
  api_secret: env.CLOUDINARY_API_SECRET,
  secure: true,
});

export interface CloudinaryUploadParams {
  uploadUrl: string;
  publicId: string;
  timestamp: number;
  apiKey: string;
  signature: string;
}

/**
 * Genera parámetros de upload firmados para que Flutter suba directamente
 * a Cloudinary sin exponer el api_secret.
 *
 * Flutter hace: POST multipart/form-data a uploadUrl con estos campos + el archivo.
 * Resource type "raw" acepta cualquier binario (audio cifrado AES-256).
 */
export function generateCloudinaryUploadParams(
  sessionId: string,
  count: number,
): CloudinaryUploadParams[] {
  const params: CloudinaryUploadParams[] = [];

  for (let i = 0; i < count; i++) {
    const publicId = `panic/${sessionId}/${i}`;
    const timestamp = Math.round(Date.now() / 1000);

    const signature = cloudinary.utils.api_sign_request(
      { timestamp, public_id: publicId },
      env.CLOUDINARY_API_SECRET,
    );

    params.push({
      uploadUrl: `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/raw/upload`,
      publicId,
      timestamp,
      apiKey: env.CLOUDINARY_API_KEY,
      signature,
    });
  }

  return params;
}
