import { io, type Socket } from 'socket.io-client';

import { API_BASE_URL } from '../constants/api';
import { firebaseAuthRepository } from '../../features/auth/infrastructure/firebase-auth.repository';

let socket: Socket | null = null;

/**
 * Devuelve un socket.io-client singleton autenticado con Firebase ID Token.
 * Reusa la conexión si ya existe.
 *
 * Notas:
 * - Usamos API_BASE_URL (http://) en lugar de WS_URL (ws://). socket.io maneja
 *   el upgrade internamente y empieza por HTTP long-polling antes de pasar a WS.
 *   Forzar transports:['websocket'] saltea el handshake polling y causa fallos
 *   intermitentes en algunos entornos (Firefox, dev servers, proxies).
 * - El handshake.auth.token lo lee el backend en auth.socket.ts.
 */
export async function getSocket(): Promise<Socket> {
  if (socket?.connected) return socket;

  const token = await firebaseAuthRepository.getIdToken();

  if (!socket) {
    socket = io(API_BASE_URL, {
      autoConnect:    false,
      withCredentials: true,
      auth:           { token },
      reconnection:   true,
      reconnectionDelay:    1000,
      reconnectionAttempts: 5,
    });

    if (import.meta.env.DEV) {
      // eslint-disable-next-line no-console
      socket.on('connect_error', (err) => console.warn('[ws] connect_error:', err.message));
    }
  } else {
    socket.auth = { token };
  }

  if (!socket.connected) {
    socket.connect();
  }

  return socket;
}

export function disconnectSocket(): void {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
}
