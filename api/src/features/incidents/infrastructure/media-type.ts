/**
 * media-type — clasificación de `mediaUrls` por extensión (extension-sniff).
 *
 * `mediaUrls` son paths `gs://` que el cliente sube primero a Firebase Storage;
 * el uploader móvil (`firebase_storage_service.dart:_extensionFor()`) deriva la
 * extensión desde el MIME real del archivo al momento de subir, por lo que
 * sniffear la extensión del path es suficientemente confiable para un MVP
 * fail-open, sin necesitar un array `mediaTypes[]` paralelo desde el cliente.
 */

export type MediaKind = 'image' | 'video' | 'other';

const IMAGE_EXT = /\.(jpe?g|png|webp|heic|heif|gif)$/i;
const VIDEO_EXT = /\.(mp4|mov|webm|m4v|3gp)$/i;

export function classifyMediaUrl(url: string): MediaKind {
  const path = url.split('?')[0]; // strip signed-URL query string
  if (IMAGE_EXT.test(path)) return 'image';
  if (VIDEO_EXT.test(path)) return 'video';
  return 'other';
}

export function isAllowedMedia(url: string): boolean {
  return classifyMediaUrl(url) !== 'other';
}
