const IV_LENGTH_BYTES = 12;

function base64ToBytes(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/**
 * Importa la clave AES-256-GCM de la sesion. `extractable: false` es
 * deliberado: ni este mismo modulo puede volcar la clave a un string
 * despues de importada — solo sirve para decrypt().
 */
export async function importAesKey(base64Key: string): Promise<CryptoKey> {
  const rawKey = base64ToBytes(base64Key);
  return crypto.subtle.importKey('raw', rawKey, 'AES-GCM', false, ['decrypt']);
}

/**
 * Formato de bloque cifrado (ver mobile/lib/core/utils/encryption_util.dart):
 * [ IV: 12 bytes ][ ciphertext ][ tag: 16 bytes ]
 */
export function splitIvAndCiphertext(buffer: ArrayBuffer): { iv: Uint8Array; ciphertext: Uint8Array } {
  const bytes = new Uint8Array(buffer);
  return {
    iv: bytes.slice(0, IV_LENGTH_BYTES),
    ciphertext: bytes.slice(IV_LENGTH_BYTES),
  };
}

/**
 * Descifra un bloque de audio. AES-GCM es cifrado autenticado: si el bloque
 * fue alterado o la clave no corresponde, esto lanza — no hay riesgo de
 * reproducir audio corrupto silenciosamente. El caller debe capturar el
 * throw y mostrarlo como error de ese bloque puntual.
 */
export async function decryptBlock(
  key: CryptoKey,
  iv: Uint8Array,
  ciphertext: Uint8Array,
): Promise<ArrayBuffer> {
  return crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ciphertext);
}
