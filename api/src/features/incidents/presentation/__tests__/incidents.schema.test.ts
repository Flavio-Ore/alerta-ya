/**
 * incidents.schema — mediaUrls allow-list unit tests.
 *
 * Server-side MIME allow-list (S1): rejects documents/other file types,
 * accepts images and video. Extension-sniff on the gs:// path (api-only).
 */
import { describe, it, expect } from 'vitest';

import { createReportSchema } from '../incidents.schema';

function baseInput(mediaUrls: string[]) {
  return {
    lat: -12.1167,
    lng: -77.0372,
    type: 'ROBBERY',
    formData: {},
    mediaUrls,
  };
}

describe('createReportSchema — mediaUrls allow-list', () => {
  it('GIVEN a .pdf URL THEN validation fails (hard reject)', () => {
    const result = createReportSchema.safeParse(baseInput(['gs://bucket/evidence/doc.pdf']));
    expect(result.success).toBe(false);
  });

  it('GIVEN a .jpg URL THEN validation passes', () => {
    const result = createReportSchema.safeParse(baseInput(['gs://bucket/evidence/photo.jpg']));
    expect(result.success).toBe(true);
  });

  it('GIVEN an .mp4 URL THEN validation passes', () => {
    const result = createReportSchema.safeParse(baseInput(['gs://bucket/evidence/clip.mp4']));
    expect(result.success).toBe(true);
  });

  it('GIVEN a signed https URL with query string and image extension THEN validation passes', () => {
    const result = createReportSchema.safeParse(
      baseInput(['https://storage.googleapis.com/bucket/photo.png?X-Goog-Signature=abc']),
    );
    expect(result.success).toBe(true);
  });

  it('GIVEN mediaUrls is empty THEN validation passes (no media, never mandatory)', () => {
    const result = createReportSchema.safeParse(baseInput([]));
    expect(result.success).toBe(true);
  });

  it('GIVEN a mix of valid image and invalid doc THEN validation fails', () => {
    const result = createReportSchema.safeParse(
      baseInput(['gs://bucket/photo.jpg', 'gs://bucket/doc.docx']),
    );
    expect(result.success).toBe(false);
  });
});
