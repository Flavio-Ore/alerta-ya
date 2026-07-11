import { useEffect, useRef, useState } from 'react';
import { Headphones, Loader2, AlertCircle, PlayCircle } from 'lucide-react';

import { useReleaseRecordingKey } from '../infrastructure/panic.api';
import { importAesKey, decryptBlock, splitIvAndCiphertext } from '../infrastructure/recording.crypto';

interface Props {
  sessionId: string;
  recordingBlocksCount: number;
}

type PlayerState =
  | { phase: 'idle' }
  | { phase: 'loading' }
  | { phase: 'error'; message: string }
  | { phase: 'ready'; audioUrl: string; failedBlocks: number[] };

/**
 * Unica pieza del frontend que toca crypto.subtle. La aesKey vive solo en el
 * scope de fetchAndDecrypt — nunca en estado de React, nunca en cache de
 * TanStack Query, nunca logueada.
 */
export function RecordingPlayer({ sessionId, recordingBlocksCount }: Props) {
  const releaseKey = useReleaseRecordingKey();
  const [state, setState] = useState<PlayerState>({ phase: 'idle' });
  const audioUrlRef = useRef<string | null>(null);

  useEffect(() => {
    return () => {
      if (audioUrlRef.current) {
        URL.revokeObjectURL(audioUrlRef.current);
      }
    };
  }, []);

  if (recordingBlocksCount === 0) {
    return (
      <p className="text-xs text-ay-text-secondary italic">
        Sin grabación disponible para esta sesión.
      </p>
    );
  }

  function handleListen() {
    setState({ phase: 'loading' });
    releaseKey.mutate(sessionId, {
      onSuccess: async (result) => {
        try {
          const key = await importAesKey(result.aesKey);
          const decryptedParts: ArrayBuffer[] = [];
          const failedBlocks: number[] = [];

          for (const block of result.blocks) {
            try {
              const res = await fetch(block.url);
              if (!res.ok) throw new Error('signed-url-expired');
              const buffer = await res.arrayBuffer();
              const { iv, ciphertext } = splitIvAndCiphertext(buffer);
              const plaintext = await decryptBlock(key, iv, ciphertext);
              decryptedParts.push(plaintext);
            } catch {
              failedBlocks.push(block.index);
            }
          }

          if (decryptedParts.length === 0) {
            setState({
              phase: 'error',
              message: 'El enlace expiró o no se pudo descifrar ningún bloque. Pedí la clave de nuevo.',
            });
            return;
          }

          const blob = new Blob(decryptedParts, { type: 'audio/aac' });
          const audioUrl = URL.createObjectURL(blob);
          audioUrlRef.current = audioUrl;
          setState({ phase: 'ready', audioUrl, failedBlocks });
        } catch {
          setState({ phase: 'error', message: 'No se pudo descifrar la grabación.' });
        }
      },
      onError: (err: unknown) => {
        const status = (err as { response?: { status?: number } })?.response?.status;
        if (status === 403) {
          setState({
            phase: 'error',
            message: 'Tu cuenta no tiene permisos de autoridad para esta acción.',
          });
          return;
        }
        setState({ phase: 'error', message: 'No se pudo obtener la clave de la grabación.' });
      },
    });
  }

  if (state.phase === 'idle') {
    return (
      <button
        onClick={handleListen}
        className="flex items-center gap-2 bg-ay-primary text-white px-4 py-2 text-xs font-black uppercase tracking-widest hover:bg-ay-primary/90 transition-all"
      >
        <Headphones size={14} /> Escuchar grabación
      </button>
    );
  }

  if (state.phase === 'loading') {
    return (
      <div className="flex items-center gap-2 text-xs text-ay-text-secondary">
        <Loader2 size={14} className="animate-spin" /> Descifrando grabación…
      </div>
    );
  }

  if (state.phase === 'error') {
    return (
      <div className="flex items-center gap-2 text-xs text-ay-critical">
        <AlertCircle size={14} /> {state.message}
        <button
          onClick={() => setState({ phase: 'idle' })}
          className="underline font-black uppercase tracking-widest hover:no-underline"
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2 text-xs text-ay-text-secondary">
        <PlayCircle size={14} /> Grabación descifrada
      </div>
      <audio src={state.audioUrl} controls className="w-full" />
      {state.failedBlocks.length > 0 && (
        <p className="text-[10px] text-ay-critical">
          {state.failedBlocks.length} bloque(s) no se pudieron descifrar y fueron omitidos.
        </p>
      )}
    </div>
  );
}
