import { describe, it, expect } from 'vitest';
import { importAesKey, decryptBlock, splitIvAndCiphertext } from './recording.crypto';

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

async function encryptFixture(plaintext: string, rawKey: Uint8Array) {
  const key = await crypto.subtle.importKey('raw', rawKey as any, 'AES-GCM', false, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    new TextEncoder().encode(plaintext),
  );
  const combined = new Uint8Array(iv.byteLength + ciphertext.byteLength);
  combined.set(iv, 0);
  combined.set(new Uint8Array(ciphertext), iv.byteLength);
  return combined;
}

describe('recording.crypto', () => {
  const rawKey = crypto.getRandomValues(new Uint8Array(32));

  it('GIVEN un bloque cifrado valido THEN splitIvAndCiphertext separa 12 bytes de IV del resto', async () => {
    const combined = await encryptFixture('hola', rawKey);
    const { iv, ciphertext } = splitIvAndCiphertext(combined.buffer);
    expect(iv.byteLength).toBe(12);
    expect(ciphertext.byteLength).toBe(combined.byteLength - 12);
  });

  it('GIVEN clave y bloque cifrado correctos THEN decryptBlock devuelve el plaintext original', async () => {
    const combined = await encryptFixture('audio-plano-de-prueba', rawKey);
    const { iv, ciphertext } = splitIvAndCiphertext(combined.buffer);

    const key = await importAesKey(btoa(String.fromCharCode(...rawKey)));
    const plaintext = await decryptBlock(key, iv, ciphertext);

    expect(new TextDecoder().decode(plaintext)).toBe('audio-plano-de-prueba');
  });

  it('GIVEN ciphertext alterado THEN decryptBlock lanza excepcion (autenticacion GCM)', async () => {
    const combined = await encryptFixture('dato-sensible', rawKey);
    const { iv, ciphertext } = splitIvAndCiphertext(combined.buffer);
    const tampered = new Uint8Array(ciphertext);
    tampered[0] = tampered[0] ^ 0xff; // corrompe un byte

    const key = await importAesKey(btoa(String.fromCharCode(...rawKey)));

    await expect(decryptBlock(key, iv, tampered)).rejects.toThrow();
  });

  it('GIVEN importAesKey THEN la clave resultante no es extractable', async () => {
    const key = await importAesKey(toBase64(rawKey));
    expect(key.extractable).toBe(false);
  });
});
