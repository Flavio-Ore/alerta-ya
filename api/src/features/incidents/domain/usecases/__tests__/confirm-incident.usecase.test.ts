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

function makeDeps(incident: ReturnType<typeof fakeIncident>) {
  const incrementConfirm = vi.fn().mockResolvedValue({ ...incident, confirmCount: 1 });
  const incrementDeny = vi.fn().mockResolvedValue({ ...incident, denyCount: 1 });
  const incidentRepo = {
    findById: vi.fn().mockResolvedValue(incident),
    incrementConfirm,
    incrementDeny,
    updateStatus: vi.fn(),
  } as unknown as IncidentRepository;

  const redis = { set: vi.fn().mockResolvedValue('OK') } as never;
  return { deps: { incidentRepo, redis }, incrementConfirm };
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
      { incidentId: 'inc-1', uid: 'u1', vote: 'yes', lat: INC_LAT, lng: INC_LNG }, // same point
      deps,
    );
    expect(incrementConfirm).toHaveBeenCalledOnce();
    expect(dto.confirmCount).toBe(1);
  });
});
