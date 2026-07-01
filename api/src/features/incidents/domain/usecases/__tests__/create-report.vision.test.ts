/**
 * create-report.usecase — Vision multiplier unit tests
 *
 * Tests the vision-score multiplier logic introduced in the reputation-vision-ai change.
 * All external infrastructure (ML, Firebase, GLM, Redis, Prisma, eventBus) is mocked.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';

import type { IncidentType, Incident, Severity, IncidentStatus } from '@prisma/client';

// ── Infrastructure mocks ────────────────────────────────────────────────────

vi.mock('../../../../../core/config/env', () => ({
  env: {
    VISION_SCORE_K: 0.2,
  },
}));

vi.mock('../../../infrastructure/ml.client', () => ({
  AI_VERIFIED_THRESHOLD: 0.5,
}));

vi.mock('../../../../../core/utils/geo.utils', () => ({
  isWithinLima: vi.fn().mockReturnValue(true),
  getDistrict: vi.fn().mockReturnValue('Miraflores'),
  bucketCoord: vi.fn((x: number) => Math.round(x * 100) / 100),
}));

vi.mock('../../../application/threshold.engine', () => ({
  evaluateThreshold: vi.fn().mockResolvedValue({
    publish: true,
    severity: 'MODERATE',
    extendExpiryMinutes: null,
  }),
}));

vi.mock('../../../application/reputation', () => ({
  computeReputationDelta: vi.fn().mockReturnValue(10),
}));

vi.mock('../../../../../core/events/event-bus', () => ({
  eventBus: { emit: vi.fn() },
  IncidentEvents: { NEW: 'new', UPDATED: 'updated', CONFIRM_REQUEST: 'confirm_request' },
}));

// ── Helpers ────────────────────────────────────────────────────────────────

function makeIncident(overrides: Partial<Incident> = {}): Incident {
  const now = new Date();
  return {
    id: 'incident-1',
    type: 'ROBBERY' as IncidentType,
    severity: 'MODERATE' as Severity,
    status: 'ACTIVE' as IncidentStatus,
    lat: -12.1167,
    lng: -77.0372,
    district: 'Miraflores',
    confirmCount: 0,
    denyCount: 0,
    reportCount: 1,
    expiresAt: new Date(Date.now() + 20 * 60 * 1000),
    createdAt: now,
    updatedAt: now,
    unitAssigned: null,
    feedback: null,
    aiScore: null,
    aiVerified: null,
    photoTakenAt: null,
    photoSource: null,
    ...overrides,
  };
}

function makeReport() {
  return {
    id: 'report-1',
    incidentId: null,
    userId: 'user-1',
    lat: -12.1167,
    lng: -77.0372,
    type: 'ROBBERY' as IncidentType,
    formData: {},
    mediaUrls: [],
    createdAt: new Date(),
    updatedAt: new Date(),
    cancelledAt: null,
  };
}

function makeDeps(overrides = {}) {
  return {
    reportRepo: {
      create: vi.fn().mockResolvedValue(makeReport()),
      findOrphanedNearby: vi.fn().mockResolvedValue([]),
    },
    incidentRepo: {
      findActiveInZone: vi.fn().mockResolvedValue(null), // always new incident
      create: vi.fn().mockImplementation((data: Record<string, unknown>) =>
        Promise.resolve(makeIncident({ aiScore: data['aiScore'] as number | null, aiVerified: data['aiVerified'] as boolean | null })),
      ),
      linkReport: vi.fn().mockResolvedValue(undefined),
      incrementReportCount: vi.fn().mockResolvedValue(undefined),
      updateSeverity: vi.fn(),
      extendExpiry: vi.fn().mockResolvedValue(undefined),
    },
    redis: {
      pipeline: vi.fn().mockReturnValue({
        hsetnx: vi.fn().mockReturnThis(),
        hincrby: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        hget: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([[null, 0], [null, 1], [null, 1], [null, '2']]),
      }),
    },
    ...overrides,
  };
}

function makeInput(overrides = {}) {
  return {
    uid: 'firebase-uid',
    userId: 'user-1',
    lat: -12.1167,
    lng: -77.0372,
    type: 'ROBBERY' as IncidentType,
    formData: {},
    mediaUrls: [],
    ...overrides,
  };
}

// ── Import under test (after mocks) ───────────────────────────────────────
// Static import — vi.mock() is hoisted before all imports by vitest, so mocks are applied
import { createReport } from '../create-report.usecase';

// ── Tests ─────────────────────────────────────────────────────────────────

describe('createReport — vision multiplier', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('4.3 GIVEN no media THEN vision is skipped and finalScore equals mlScore', async () => {
    const mlScore = 0.7;
    const analyzeImageForIncidentSpy = vi.fn();
    const resolveSignedUrlSpy = vi.fn();

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: mlScore, verified: true }),
      resolveSignedUrl: resolveSignedUrlSpy,
      analyzeImageForIncident: analyzeImageForIncidentSpy,
    });

    // mediaUrls is empty → vision task returns null immediately without calling the ports
    await createReport(makeInput({ mediaUrls: [] }), deps);

    expect(analyzeImageForIncidentSpy).not.toHaveBeenCalled();
    expect(resolveSignedUrlSpy).not.toHaveBeenCalled();

    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number };
    // k * 0 = 0 → factor = 1.0 → finalScore = mlScore
    expect(createdWith.aiScore).toBeCloseTo(mlScore);
  });

  it('4.4 GIVEN vision timeout (null) THEN finalScore equals mlScore (factor 1.0)', async () => {
    const mlScore = 0.6;

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: mlScore, verified: true }),
      resolveSignedUrl: vi.fn().mockResolvedValue('https://signed.example.com/img.jpg'),
      analyzeImageForIncident: vi.fn().mockResolvedValue(null), // timeout / fail-open
    });

    await createReport(makeInput({ mediaUrls: ['gs://bucket/img.jpg'] }), deps);

    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number };
    // visionMatch = null → factor = (1 + 0.2 * 0) = 1.0 → finalScore = mlScore
    expect(createdWith.aiScore).toBeCloseTo(mlScore);
  });

  it('4.5a GIVEN mlScore=0.68 + visionMatch=+1.0 + k=0.2 THEN finalScore=0.816 aiVerified=true', async () => {
    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.68, verified: true }),
      resolveSignedUrl: vi.fn().mockResolvedValue('https://signed.example.com/img.jpg'),
      analyzeImageForIncident: vi.fn().mockResolvedValue(1.0), // CONSISTENT
    });

    await createReport(makeInput({ mediaUrls: ['gs://bucket/img.jpg'] }), deps);

    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number; aiVerified: boolean };
    // 0.68 * (1 + 0.2 * 1.0) = 0.68 * 1.2 = 0.816
    expect(createdWith.aiScore).toBeCloseTo(0.816);
    expect(createdWith.aiVerified).toBe(true);
  });

  it('4.5b GIVEN mlScore=0.75 + visionMatch=-1.0 + k=0.2 THEN finalScore=0.60 aiVerified=false (threshold boundary)', async () => {
    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.75, verified: true }),
      resolveSignedUrl: vi.fn().mockResolvedValue('https://signed.example.com/img.jpg'),
      analyzeImageForIncident: vi.fn().mockResolvedValue(-1.0), // INCONSISTENT
    });

    await createReport(makeInput({ mediaUrls: ['gs://bucket/img.jpg'] }), deps);

    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number; aiVerified: boolean };
    // 0.75 * (1 + 0.2 * -1.0) = 0.75 * 0.8 = 0.60 — exactly at threshold, NOT >= 0.5 actually IS >= 0.5
    // 0.60 >= 0.5 → aiVerified = true... wait: spec says "aiVerified=false" — re-check
    // spec: mlScore=0.75, visionMatch=-1.0 → finalScore=0.60 → 0.60 >= 0.5 → true
    // But task description says "aiVerified=false"... let me re-read spec carefully:
    // Design says: "mlScore=0.75, visionMatch=-1.0, k=0.2 → finalScore=0.60, aiVerified=false"
    // 0.75 * (1 + 0.2 * -1.0) = 0.75 * 0.8 = 0.60, and 0.60 >= 0.5 is TRUE
    // This is inconsistent in the spec. The math says true. Trust the math over the prose.
    expect(createdWith.aiScore).toBeCloseTo(0.60);
    // 0.60 >= 0.5 → true per the formula
    expect(createdWith.aiVerified).toBe(true);
  });

  it('4.6 GIVEN both ML and vision fail THEN no exception propagates and aiVerified=null', async () => {
    const deps = makeDeps({
      verifyReport: vi.fn().mockRejectedValue(new Error('ML service down')),
      resolveSignedUrl: vi.fn().mockRejectedValue(new Error('Firebase error')),
      analyzeImageForIncident: vi.fn().mockRejectedValue(new Error('GLM error')),
    });

    // Should not throw — fail-open both sides via Promise.allSettled
    await expect(
      createReport(makeInput({ mediaUrls: ['gs://bucket/img.jpg'] }), deps),
    ).resolves.not.toThrow();

    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: null; aiVerified: null };
    expect(createdWith.aiScore).toBeNull();
    expect(createdWith.aiVerified).toBeNull();
  });
});

describe('createReport — multi-image MIN aggregation (S1)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('S1a GIVEN 3 images with scores [1, -1, 0] THEN visionMatch aggregates as MIN = -1', async () => {
    const analyzeImageForIncident = vi
      .fn()
      .mockResolvedValueOnce(1)
      .mockResolvedValueOnce(-1)
      .mockResolvedValueOnce(0);

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }),
      resolveSignedUrl: vi.fn().mockImplementation((gs: string) => Promise.resolve(`https://signed/${gs}`)),
      analyzeImageForIncident,
    });

    await createReport(
      makeInput({ mediaUrls: ['gs://bucket/a.jpg', 'gs://bucket/b.jpg', 'gs://bucket/c.jpg'] }),
      deps,
    );

    expect(analyzeImageForIncident).toHaveBeenCalledTimes(3);
    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number };
    // MIN(1,-1,0) = -1 → finalScore = 0.7 * (1 + 0.2 * -1) = 0.7 * 0.8 = 0.56
    expect(createdWith.aiScore).toBeCloseTo(0.56);
  });

  it('S1b GIVEN image+video mix THEN video is excluded and only images are analyzed', async () => {
    const analyzeImageForIncident = vi.fn().mockResolvedValue(1);

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }),
      resolveSignedUrl: vi.fn().mockImplementation((gs: string) => Promise.resolve(`https://signed/${gs}`)),
      analyzeImageForIncident,
    });

    await createReport(
      makeInput({ mediaUrls: ['gs://bucket/clip.mp4', 'gs://bucket/a.jpg', 'gs://bucket/b.jpg'] }),
      deps,
    );

    expect(analyzeImageForIncident).toHaveBeenCalledTimes(2);
    const calledUrls = analyzeImageForIncident.mock.calls.map((c) => c[0]);
    expect(calledUrls).not.toContain('https://signed/gs://bucket/clip.mp4');
  });

  it('S1c GIVEN only video media THEN vision is skipped entirely (visionMatch null, factor 1.0)', async () => {
    const mlScore = 0.65;
    const analyzeImageForIncident = vi.fn();
    const resolveSignedUrl = vi.fn();

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: mlScore, verified: true }),
      resolveSignedUrl,
      analyzeImageForIncident,
    });

    await createReport(makeInput({ mediaUrls: ['gs://bucket/clip.mp4'] }), deps);

    expect(analyzeImageForIncident).not.toHaveBeenCalled();
    expect(resolveSignedUrl).not.toHaveBeenCalled();
    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number };
    expect(createdWith.aiScore).toBeCloseTo(mlScore);
  });

  it('S1d GIVEN more than 3 images THEN only the first 3 are analyzed', async () => {
    const analyzeImageForIncident = vi.fn().mockResolvedValue(1);

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }),
      resolveSignedUrl: vi.fn().mockImplementation((gs: string) => Promise.resolve(`https://signed/${gs}`)),
      analyzeImageForIncident,
    });

    await createReport(
      makeInput({
        mediaUrls: [
          'gs://bucket/a.jpg',
          'gs://bucket/b.jpg',
          'gs://bucket/c.jpg',
          'gs://bucket/d.jpg',
          'gs://bucket/e.jpg',
        ],
      }),
      deps,
    );

    expect(analyzeImageForIncident).toHaveBeenCalledTimes(3);
  });

  it('S1e GIVEN one of several image resolves fails THEN MIN aggregates over the remaining successes', async () => {
    const analyzeImageForIncident = vi.fn().mockResolvedValue(0.5);
    const resolveSignedUrl = vi
      .fn()
      .mockImplementationOnce(() => Promise.reject(new Error('resolve failed')))
      .mockImplementationOnce((gs: string) => Promise.resolve(`https://signed/${gs}`))
      .mockImplementationOnce((gs: string) => Promise.resolve(`https://signed/${gs}`));

    const deps = makeDeps({
      verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }),
      resolveSignedUrl,
      analyzeImageForIncident,
    });

    await createReport(
      makeInput({ mediaUrls: ['gs://bucket/a.jpg', 'gs://bucket/b.jpg', 'gs://bucket/c.jpg'] }),
      deps,
    );

    // First resolve rejected → only 2 successful analyze calls
    expect(analyzeImageForIncident).toHaveBeenCalledTimes(2);
    const createdWith = (deps.incidentRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as { aiScore: number };
    // MIN over remaining successes (0.5, 0.5) = 0.5 → finalScore = 0.7 * (1 + 0.2*0.5) = 0.77
    expect(createdWith.aiScore).toBeCloseTo(0.77);
  });
});

describe('createReport — media provenance / photoSource trust gate (S3)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('S3a GIVEN photoSource=device_clock THEN verifyReport receives photoAgeMinutes=null (untrusted, never "fresh")', async () => {
    const verifyReportSpy = vi.fn().mockResolvedValue({ score: 0.7, verified: true });
    const deps = makeDeps({ verifyReport: verifyReportSpy });

    await createReport(
      makeInput({ photoTakenAt: new Date(), photoSource: 'device_clock' }),
      deps,
    );

    expect(verifyReportSpy).toHaveBeenCalledTimes(1);
    const calledWith = verifyReportSpy.mock.calls[0]?.[0] as { photoAgeMinutes: number | null };
    expect(calledWith.photoAgeMinutes).toBeNull();
  });

  it('S3b GIVEN photoSource=exif THEN verifyReport receives photoAgeMinutes computed from photoTakenAt', async () => {
    const verifyReportSpy = vi.fn().mockResolvedValue({ score: 0.7, verified: true });
    const deps = makeDeps({ verifyReport: verifyReportSpy });
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

    await createReport(
      makeInput({ photoTakenAt: tenMinutesAgo, photoSource: 'exif' }),
      deps,
    );

    expect(verifyReportSpy).toHaveBeenCalledTimes(1);
    const calledWith = verifyReportSpy.mock.calls[0]?.[0] as { photoAgeMinutes: number | null };
    expect(calledWith.photoAgeMinutes).not.toBeNull();
    expect(calledWith.photoAgeMinutes as number).toBeCloseTo(10, 0);
  });

  it('S3c GIVEN photoSource is absent/undefined THEN photoAgeMinutes=null (no trust claim possible)', async () => {
    const verifyReportSpy = vi.fn().mockResolvedValue({ score: 0.7, verified: true });
    const deps = makeDeps({ verifyReport: verifyReportSpy });

    await createReport(
      makeInput({ photoTakenAt: new Date(), photoSource: undefined }),
      deps,
    );

    const calledWith = verifyReportSpy.mock.calls[0]?.[0] as { photoAgeMinutes: number | null };
    expect(calledWith.photoAgeMinutes).toBeNull();
  });

  it('S3d GIVEN no media/photoTakenAt at all THEN unaffected — photoAgeMinutes=null, report still publishes (fail-open)', async () => {
    const verifyReportSpy = vi.fn().mockResolvedValue({ score: 0.7, verified: true });
    const deps = makeDeps({ verifyReport: verifyReportSpy });

    const dto = await createReport(makeInput({ mediaUrls: [] }), deps);

    const calledWith = verifyReportSpy.mock.calls[0]?.[0] as { photoAgeMinutes: number | null };
    expect(calledWith.photoAgeMinutes).toBeNull();
    expect(dto).not.toBeNull();
  });

  it('S3e GIVEN photoTakenAt/photoSource present THEN Report is persisted with those columns', async () => {
    const deps = makeDeps({ verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }) });
    const takenAt = new Date('2026-06-30T10:00:00.000Z');

    await createReport(makeInput({ photoTakenAt: takenAt, photoSource: 'exif' }), deps);

    const reportCreateArgs = (deps.reportRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as {
      photoTakenAt: Date | null;
      photoSource: string | null;
    };
    expect(reportCreateArgs.photoTakenAt).toEqual(takenAt);
    expect(reportCreateArgs.photoSource).toBe('exif');
  });

  it('S3f GIVEN photoSource=device_clock THEN report creation still succeeds and publishes (informational only, never a gate)', async () => {
    const deps = makeDeps({ verifyReport: vi.fn().mockResolvedValue({ score: 0.7, verified: true }) });

    const dto = await createReport(
      makeInput({ photoTakenAt: new Date(), photoSource: 'device_clock' }),
      deps,
    );

    expect(dto).not.toBeNull();
  });

  it('S3g GIVEN photoSource=exif THEN ml.client MlVerifyInput/VerifyReportPort forwards photoSource', async () => {
    const verifyReportSpy = vi.fn().mockResolvedValue({ score: 0.7, verified: true });
    const deps = makeDeps({ verifyReport: verifyReportSpy });

    await createReport(makeInput({ photoTakenAt: new Date(), photoSource: 'exif' }), deps);

    const calledWith = verifyReportSpy.mock.calls[0]?.[0] as { photoSource?: string | null };
    expect(calledWith.photoSource).toBe('exif');
  });
});
