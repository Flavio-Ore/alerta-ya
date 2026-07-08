import { describe, it, expect, vi } from 'vitest';
import type { Report } from '@prisma/client';

import { getIncidentEvidence } from '../get-incident-evidence.usecase';
import { AppError } from '../../../../../core/errors/AppError';

function report(userId: string, mediaUrls: string[]): Report {
  return { userId, mediaUrls } as unknown as Report;
}

// Resolver que devuelve una URL firmada determinista, o null para simular fallo.
function resolverOk(gsPath: string): Promise<string | null> {
  return Promise.resolve(`https://signed/${gsPath.replace('gs://', '')}`);
}

describe('getIncidentEvidence', () => {
  const authority = { prismaUserId: '', isAuthority: true };
  const citizenA = { prismaUserId: 'user-A', isAuthority: false };

  it('GIVEN authority THEN resolves evidence from ALL reports of the incident', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([
        report('user-A', ['gs://b/a.jpg']),
        report('user-B', ['gs://b/c.mp4']),
      ]),
    };
    const result = await getIncidentEvidence('inc-1', authority, {
      reportRepo,
      resolveSignedUrl: resolverOk,
    });
    expect(result).toHaveLength(2);
    expect(result.map((e) => e.kind).sort()).toEqual(['image', 'video']);
  });

  it('GIVEN citizen THEN resolves ONLY their own reports evidence', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([
        report('user-A', ['gs://b/mine.jpg']),
        report('user-B', ['gs://b/theirs.jpg']),
      ]),
    };
    const result = await getIncidentEvidence('inc-1', citizenA, {
      reportRepo,
      resolveSignedUrl: resolverOk,
    });
    expect(result).toHaveLength(1);
    expect(result[0]!.signedUrl).toContain('mine.jpg');
    expect(result[0]!.signedUrl).not.toContain('theirs.jpg');
  });

  it('GIVEN citizen with NO own reports on the incident THEN throws 403 (no leak)', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([report('user-B', ['gs://b/x.jpg'])]),
    };
    await expect(
      getIncidentEvidence('inc-1', citizenA, { reportRepo, resolveSignedUrl: resolverOk }),
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it('GIVEN authority AND no reports THEN returns [] (200, not 403)', async () => {
    const reportRepo = { findByIncidentId: vi.fn().mockResolvedValue([]) };
    const result = await getIncidentEvidence('inc-1', authority, {
      reportRepo,
      resolveSignedUrl: resolverOk,
    });
    expect(result).toEqual([]);
  });

  it('FAIL-OPEN: a media that resolves to null is omitted, the rest are returned', async () => {
    const reportRepo = {
      findByIncidentId: vi
        .fn()
        .mockResolvedValue([report('user-A', ['gs://b/ok.jpg', 'gs://b/broken.jpg'])]),
    };
    const resolver = (gs: string) =>
      Promise.resolve(gs.includes('broken') ? null : `https://signed/${gs}`);
    const result = await getIncidentEvidence('inc-1', authority, {
      reportRepo,
      resolveSignedUrl: resolver,
    });
    expect(result).toHaveLength(1);
    expect(result[0]!.signedUrl).toContain('ok.jpg');
  });

  it('non image/video media (e.g. .pdf) is excluded', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([report('user-A', ['gs://b/doc.pdf'])]),
    };
    const result = await getIncidentEvidence('inc-1', authority, {
      reportRepo,
      resolveSignedUrl: resolverOk,
    });
    expect(result).toEqual([]);
  });

  it('output items expose ONLY signedUrl + kind — no reporter identity', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([report('user-A', ['gs://b/a.jpg'])]),
    };
    const result = await getIncidentEvidence('inc-1', authority, {
      reportRepo,
      resolveSignedUrl: resolverOk,
    });
    expect(Object.keys(result[0]!).sort()).toEqual(['kind', 'signedUrl']);
  });

  it('throws AppError specifically (403) for the forbidden citizen case', async () => {
    const reportRepo = {
      findByIncidentId: vi.fn().mockResolvedValue([report('user-B', ['gs://b/x.jpg'])]),
    };
    await expect(
      getIncidentEvidence('inc-1', citizenA, { reportRepo, resolveSignedUrl: resolverOk }),
    ).rejects.toBeInstanceOf(AppError);
  });
});
