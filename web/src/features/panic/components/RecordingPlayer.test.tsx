import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import { RecordingPlayer } from './RecordingPlayer';
import { useReleaseRecordingKey } from '../infrastructure/panic.api';
import { importAesKey, decryptBlock, splitIvAndCiphertext } from '../infrastructure/recording.crypto';

vi.mock('../infrastructure/panic.api', () => ({
  useReleaseRecordingKey: vi.fn(),
}));

vi.mock('../infrastructure/recording.crypto', () => ({
  importAesKey: vi.fn(),
  decryptBlock: vi.fn(),
  splitIvAndCiphertext: vi.fn(),
}));

const mockHook = vi.mocked(useReleaseRecordingKey);
const mockImportAesKey = vi.mocked(importAesKey);
const mockDecryptBlock = vi.mocked(decryptBlock);
const mockSplitIvAndCiphertext = vi.mocked(splitIvAndCiphertext);
const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

describe('RecordingPlayer', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    URL.createObjectURL = vi.fn(() => 'blob:mock-url');
    URL.revokeObjectURL = vi.fn();
  });

  it('GIVEN 0 bloques THEN muestra "sin grabacion disponible" y no muestra el boton de escuchar', () => {
    mockHook.mockReturnValue({ mutate: vi.fn(), isPending: false } as never);
    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={0} />);

    expect(screen.getByText(/Sin grabación disponible/i)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Escuchar grabación/i })).not.toBeInTheDocument();
  });

  it('GIVEN click en Escuchar WHEN el backend responde 403 THEN muestra el mensaje de permisos', async () => {
    const mutate = vi.fn((_id, { onError }: { onError: (e: unknown) => void }) => {
      onError({ response: { status: 403 } });
    });
    mockHook.mockReturnValue({ mutate, isPending: false } as never);

    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={3} />);
    fireEvent.click(screen.getByRole('button', { name: /Escuchar grabación/i }));

    await waitFor(() =>
      expect(
        screen.getByText(/no tiene permisos de autoridad/i),
      ).toBeInTheDocument(),
    );
  });

  it('NUNCA pasa la aesKey a console.error ni a ningun logger', async () => {
    const mutate = vi.fn((_id, { onError }: { onError: (e: unknown) => void }) => {
      onError(new Error('fallo de red'));
    });
    mockHook.mockReturnValue({ mutate, isPending: false } as never);

    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={3} />);
    fireEvent.click(screen.getByRole('button', { name: /Escuchar grabación/i }));

    await waitFor(() => expect(screen.getByText(/no se pudo/i)).toBeInTheDocument());
    for (const call of consoleErrorSpy.mock.calls) {
      expect(JSON.stringify(call)).not.toMatch(/aesKey/i);
    }
  });

  it('GIVEN todos los bloques descifran OK THEN termina en phase ready con un <audio> renderizado', async () => {
    const mutate = vi.fn((_id, { onSuccess }: { onSuccess: (r: unknown) => void }) => {
      onSuccess({
        aesKey: 'base64key',
        blocks: [
          { index: 0, url: 'https://example.com/block-0' },
          { index: 1, url: 'https://example.com/block-1' },
        ],
      });
    });
    mockHook.mockReturnValue({ mutate, isPending: false } as never);

    mockImportAesKey.mockResolvedValue('fake-key' as never);
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(28)),
    }) as never;
    mockSplitIvAndCiphertext.mockReturnValue({
      iv: new Uint8Array(12),
      ciphertext: new Uint8Array(16),
    });
    mockDecryptBlock.mockResolvedValue(new ArrayBuffer(16));

    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={2} />);
    fireEvent.click(screen.getByRole('button', { name: /Escuchar grabación/i }));

    await waitFor(() => expect(screen.getByText(/Grabación descifrada/i)).toBeInTheDocument());

    const audioEl = document.querySelector('audio');
    expect(audioEl).toBeInTheDocument();
    expect(audioEl).toHaveAttribute('src', 'blob:mock-url');
    expect(screen.queryByText(/no se pudieron descifrar/i)).not.toBeInTheDocument();
  });

  it('GIVEN un bloque falla al descifrar/descargar THEN muestra failedBlocks y el audio igual se reproduce', async () => {
    const mutate = vi.fn((_id, { onSuccess }: { onSuccess: (r: unknown) => void }) => {
      onSuccess({
        aesKey: 'base64key',
        blocks: [
          { index: 0, url: 'https://example.com/block-0' },
          { index: 1, url: 'https://example.com/block-1' },
        ],
      });
    });
    mockHook.mockReturnValue({ mutate, isPending: false } as never);

    mockImportAesKey.mockResolvedValue('fake-key' as never);
    global.fetch = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)) })
      .mockResolvedValueOnce({ ok: true, arrayBuffer: () => Promise.resolve(new ArrayBuffer(28)) }) as never;
    mockSplitIvAndCiphertext.mockReturnValue({
      iv: new Uint8Array(12),
      ciphertext: new Uint8Array(16),
    });
    mockDecryptBlock.mockResolvedValue(new ArrayBuffer(16));

    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={2} />);
    fireEvent.click(screen.getByRole('button', { name: /Escuchar grabación/i }));

    await waitFor(() => expect(screen.getByText(/Grabación descifrada/i)).toBeInTheDocument());

    expect(document.querySelector('audio')).toBeInTheDocument();
    expect(screen.getByText(/1 bloque\(s\) no se pudieron descifrar/i)).toBeInTheDocument();
  });

  it('GIVEN estado error WHEN se hace click en Reintentar THEN vuelve a idle y muestra el boton de escuchar', async () => {
    const mutate = vi.fn((_id, { onError }: { onError: (e: unknown) => void }) => {
      onError(new Error('fallo de red'));
    });
    mockHook.mockReturnValue({ mutate, isPending: false } as never);

    render(<RecordingPlayer sessionId="s1" recordingBlocksCount={3} />);
    fireEvent.click(screen.getByRole('button', { name: /Escuchar grabación/i }));

    await waitFor(() => expect(screen.getByText(/no se pudo/i)).toBeInTheDocument());

    fireEvent.click(screen.getByRole('button', { name: /Reintentar/i }));

    expect(screen.getByRole('button', { name: /Escuchar grabación/i })).toBeInTheDocument();
  });
});
