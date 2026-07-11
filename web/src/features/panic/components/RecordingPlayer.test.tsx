import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import { RecordingPlayer } from './RecordingPlayer';
import { useReleaseRecordingKey } from '../infrastructure/panic.api';

vi.mock('../infrastructure/panic.api', () => ({
  useReleaseRecordingKey: vi.fn(),
}));

const mockHook = vi.mocked(useReleaseRecordingKey);
const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

describe('RecordingPlayer', () => {
  beforeEach(() => {
    vi.clearAllMocks();
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
});
