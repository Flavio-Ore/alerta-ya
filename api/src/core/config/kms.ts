import { KeyManagementServiceClient } from '@google-cloud/kms';

import { env } from './env';

const client = new KeyManagementServiceClient();

function keyVersionName(version: string): string {
  return `projects/${env.KMS_PROJECT_ID}/locations/${env.KMS_LOCATION_ID}/keyRings/${env.KMS_KEY_RING_ID}/cryptoKeys/${env.KMS_KEY_ID}/cryptoKeyVersions/${version}`;
}

export async function getEscrowPublicKey(): Promise<{ publicKeyPem: string; keyVersion: string }> {
  const version = env.KMS_KEY_VERSION;
  const [publicKey] = await client.getPublicKey({ name: keyVersionName(version) });
  if (!publicKey.pem) {
    throw new Error('Cloud KMS no devolvió una clave pública PEM');
  }
  return { publicKeyPem: publicKey.pem, keyVersion: version };
}

/**
 * Desenvuelve una clave de escrow usando el recurso KMS con el que fue
 * envuelta originalmente (kmsKeyName + kmsKeyVersion guardados en DB), NO el
 * reconstruido desde las env vars actuales. Si el key ring o el proyecto KMS
 * rotan después del escrow, reconstruir desde env produciría un resource name
 * distinto al usado para envolver la clave y el unwrap fallaría en silencio
 * contra la clave equivocada.
 */
export async function unwrapEscrowKey(
  wrappedKey: Buffer,
  kmsKeyName: string,
  kmsKeyVersion: string,
): Promise<Buffer> {
  const [result] = await client.asymmetricDecrypt({
    name: `${kmsKeyName}/cryptoKeyVersions/${kmsKeyVersion}`,
    ciphertext: wrappedKey,
  });
  if (!result.plaintext) {
    throw new Error('Cloud KMS no pudo desenvolver la clave (respuesta vacía)');
  }
  return Buffer.from(result.plaintext as Uint8Array);
}
