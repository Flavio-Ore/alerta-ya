/**
 * Module-level signal for the last live data refresh timestamp.
 * Updated by WebSocket hooks; read by TopBar.
 * ponytail: module var — no need for React context for a single display concern.
 */
let _lastRefreshAt: Date = new Date();
const LISTENERS = new Set<() => void>();

export function signalRefresh(): void {
  _lastRefreshAt = new Date();
  LISTENERS.forEach((fn) => fn());
}

export function getLastRefreshAt(): Date {
  return _lastRefreshAt;
}

export function subscribeToRefresh(fn: () => void): () => void {
  LISTENERS.add(fn);
  return () => LISTENERS.delete(fn);
}
