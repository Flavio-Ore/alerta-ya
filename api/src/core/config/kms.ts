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

export async function unwrapEscrowKey(wrappedKey: Buffer, keyVersion: string): Promise<Buffer> {
  const [result] = await client.asymmetricDecrypt({
    name: keyVersionName(keyVersion),
    ciphertext: wrappedKey,
  });
  if (!result.plaintext) {
    throw new Error('Cloud KMS no pudo desenvolver la clave (respuesta vacía)');
  }
  return Buffer.from(result.plaintext as Uint8Array);
}
