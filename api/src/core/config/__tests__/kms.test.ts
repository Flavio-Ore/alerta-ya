import { describe, it, expect, vi, beforeEach } from 'vitest';

const getPublicKeyMock = vi.fn();
const asymmetricDecryptMock = vi.fn();

vi.mock('@google-cloud/kms', () => ({
  KeyManagementServiceClient: vi.fn().mockImplementation(() => ({
    getPublicKey: getPublicKeyMock,
    asymmetricDecrypt: asymmetricDecryptMock,
  })),
}));

vi.mock('../env', () => ({
  env: {
    KMS_PROJECT_ID: 'test-project',
    KMS_LOCATION_ID: 'global',
    KMS_KEY_RING_ID: 'panic-escrow',
    KMS_KEY_ID: 'panic-escrow-key',
    KMS_KEY_VERSION: '1',
  },
}));

describe('kms', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getEscrowPublicKey devuelve el PEM y la versión configurada', async () => {
    getPublicKeyMock.mockResolvedValue([
      { pem: '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----\n' },
    ]);
    const { getEscrowPublicKey } = await import('../kms');

    const result = await getEscrowPublicKey();

    expect(result.keyVersion).toBe('1');
    expect(result.publicKeyPem).toContain('BEGIN PUBLIC KEY');
    expect(getPublicKeyMock).toHaveBeenCalledWith({
      name: 'projects/test-project/locations/global/keyRings/panic-escrow/cryptoKeys/panic-escrow-key/cryptoKeyVersions/1',
    });
  });

  it('getEscrowPublicKey lanza si KMS no devuelve PEM', async () => {
    getPublicKeyMock.mockResolvedValue([{ pem: null }]);
    const { getEscrowPublicKey } = await import('../kms');

    await expect(getEscrowPublicKey()).rejects.toThrow();
  });

  it('unwrapEscrowKey devuelve el buffer plaintext usando el kmsKeyName guardado, no el reconstruido desde env', async () => {
    asymmetricDecryptMock.mockResolvedValue([{ plaintext: Buffer.from('clave-secreta') }]);
    const { unwrapEscrowKey } = await import('../kms');

    const storedKeyName =
      'projects/otro-project/locations/global/keyRings/otro-ring/cryptoKeys/otra-key';
    const result = await unwrapEscrowKey(Buffer.from('wrapped'), storedKeyName, '1');

    expect(result.toString()).toBe('clave-secreta');
    expect(asymmetricDecryptMock).toHaveBeenCalledWith({
      name: 'projects/otro-project/locations/global/keyRings/otro-ring/cryptoKeys/otra-key/cryptoKeyVersions/1',
      ciphertext: Buffer.from('wrapped'),
    });
  });

  it('unwrapEscrowKey lanza si KMS devuelve plaintext vacío', async () => {
    asymmetricDecryptMock.mockResolvedValue([{ plaintext: null }]);
    const { unwrapEscrowKey } = await import('../kms');

    const storedKeyName =
      'projects/test-project/locations/global/keyRings/panic-escrow/cryptoKeys/panic-escrow-key';
    await expect(unwrapEscrowKey(Buffer.from('wrapped'), storedKeyName, '1')).rejects.toThrow();
  });
});
