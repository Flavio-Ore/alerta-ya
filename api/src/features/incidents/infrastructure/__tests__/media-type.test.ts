/**
 * media-type — clasificación de mediaUrls por extensión (extension-sniff, api-only).
 *
 * `mediaUrls` son paths gs:// subidos primero por el cliente; el uploader móvil
 * (`firebase_storage_service.dart:_extensionFor()`) deriva la extensión desde el
 * MIME real del archivo al momento de subir, por lo que sniffear la extensión del
 * path es suficientemente confiable para MVP fail-open (ver design ADR).
 */
import { describe, it, expect } from 'vitest';

import { classifyMediaUrl, isAllowedMedia } from '../media-type';

describe('classifyMediaUrl', () => {
  it('GIVEN a .jpg path THEN classifies as image', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.jpg')).toBe('image');
  });

  it('GIVEN a .jpeg path THEN classifies as image', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.jpeg')).toBe('image');
  });

  it('GIVEN a .png path THEN classifies as image', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.png')).toBe('image');
  });

  it('GIVEN a .webp path THEN classifies as image', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.webp')).toBe('image');
  });

  it('GIVEN a .heic path THEN classifies as image', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.heic')).toBe('image');
  });

  it('GIVEN uppercase extension .JPG THEN classifies as image (case-insensitive)', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/photo.JPG')).toBe('image');
  });

  it('GIVEN a .mp4 path THEN classifies as video', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/clip.mp4')).toBe('video');
  });

  it('GIVEN a .mov path THEN classifies as video', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/clip.mov')).toBe('video');
  });

  it('GIVEN a .webm path THEN classifies as video', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/clip.webm')).toBe('video');
  });

  it('GIVEN a .pdf path THEN classifies as other', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/doc.pdf')).toBe('other');
  });

  it('GIVEN a signed URL with query string THEN strips query before matching', () => {
    expect(
      classifyMediaUrl('https://storage.googleapis.com/bucket/photo.jpg?X-Goog-Signature=abc123'),
    ).toBe('image');
  });

  it('GIVEN a path with no extension THEN classifies as other', () => {
    expect(classifyMediaUrl('gs://bucket/evidence/no-extension')).toBe('other');
  });
});

describe('isAllowedMedia', () => {
  it('GIVEN an image path THEN returns true', () => {
    expect(isAllowedMedia('gs://bucket/photo.png')).toBe(true);
  });

  it('GIVEN a video path THEN returns true', () => {
    expect(isAllowedMedia('gs://bucket/clip.mp4')).toBe(true);
  });

  it('GIVEN a document path THEN returns false', () => {
    expect(isAllowedMedia('gs://bucket/doc.pdf')).toBe(false);
  });
});
