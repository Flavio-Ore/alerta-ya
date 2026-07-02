import { describe, it, expect, vi } from 'vitest';

import { confirmIncident } from '../confirm-incident.usecase';
import { IncidentRepository } from '../../repositories/incident.repository';

const INC_LAT = -12.06;
const INC_LNG = -77.03;

function fakeIncident(over: Record<string, unknown> = {}) {
  const now = new Date();
  return {
    id: 'inc-1',
    type: 'ROBBERY',
    severity: 'MODERATE',
    status: 'ACTIVE',
    lat: INC_LAT,
    lng: INC_LNG,
    district: 'Lima',
    confirmCount: 0,
    denyCount: 0,
    reportCount: 1,
    expiresAt: new Date(now.getTime() + 20 * 60_000),
    createdAt: now,
    updatedAt: now,
    unitAssigned: null,
    feedback: null,
    aiScore: null,
    aiVerified: null,
    photoTakenAt: null,
    photoSource: null,
    ...over,
  };
}

function makeRedis(over: Record<string, unknown> = {}) {
  return {
    set: vi.fn().mockResolvedValue('OK'),
    incrbyfloat: vi.fn().mockResolvedValue('1'),
    expire: vi.fn().mockResolvedValue(1),
    sadd: vi.fn().mockResolvedValue(1),
    get: vi.fn().mockResolvedValue(null),
    scard: vi.fn().mockResolvedValue(0),
    ...over,
  } as never;
}

function makeDeps(incident: ReturnType<typeof fakeIncident>, redis = makeRedis()) {
  const incrementConfirm = vi.fn().mockResolvedValue({ ...incident, confirmCount: 1 });
  const incrementDeny = vi.fn().mockResolvedValue({ ...incident, denyCount: 1 });
  const updateStatus = vi.fn().mockResolvedValue({ ...incident, status: 'CLOSED' });
  const incidentRepo = {
    findById: vi.fn().mockResolvedValue(incident),
    incrementConfirm,
    incrementDeny,
    updateStatus,
  } as unknown as IncidentRepository;

  return { deps: { incidentRepo, redis }, incrementConfirm, updateStatus };
}

describe('confirmIncident — proximity gate', () => {
  it('THROWS 403 when the voter is outside the proximity radius', async () => {
    const { deps } = makeDeps(fakeIncident());
    await expect(
      confirmIncident(
        { incidentId: 'inc-1', uid: 'u1', vote: 'yes', lat: -12.1, lng: -77.05 }, // ~6km
        deps,
      ),
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it('proceeds and counts the vote when the voter is within range', async () => {
    const { deps, incrementConfirm } = makeDeps(fakeIncident());
    const dto = await confirmIncident(
      { incidentId: 'inc-1', uid: 'u1', vote: 'yes', lat: INC_LAT, lng: INC_LNG },
      deps,
    );
    expect(incrementConfirm).toHaveBeenCalledOnce();
    expect(dto.confirmCount).toBe(1);
  });
});

describe('confirmIncident — weighted consensus close', () => {
  it('does NOT close with few distinct deniers even if weighted deny is high', async () => {
    // denyW high, confW 0, but only 1 distinct denier → below K=3
    const redis = makeRedis({
      get: vi.fn((k: string) => Promise.resolve(k.includes('deny') ? '10' : null)),
      scard: vi.fn().mockResolvedValue(1),
    });
    const { deps, updateStatus } = makeDeps(fakeIncident(), redis);
    await confirmIncident(
      { incidentId: 'inc-1', uid: 'u1', vote: 'no', lat: INC_LAT, lng: INC_LNG },
      deps,
    );
    expect(updateStatus).not.toHaveBeenCalled();
  });

  it('CLOSES when weighted deny beats confirm by margin AND ≥3 distinct deniers', async () => {
    const redis = makeRedis({
      get: vi.fn((k: string) => Promise.resolve(k.includes('deny') ? '6' : '1')),
      scard: vi.fn().mockResolvedValue(3),
    });
    const { deps, updateStatus } = makeDeps(fakeIncident(), redis);
    const dto = await confirmIncident(
      { incidentId: 'inc-1', uid: 'u1', vote: 'no', lat: INC_LAT, lng: INC_LNG },
      deps,
    );
    expect(updateStatus).toHaveBeenCalledOnce();
    expect(dto.status).toBe('CLOSED');
  });
});
