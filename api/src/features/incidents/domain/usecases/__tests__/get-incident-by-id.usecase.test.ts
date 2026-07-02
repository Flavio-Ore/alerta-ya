import { describe, it, expect } from 'vitest';

import { getIncidentById } from '../get-incident-by-id.usecase';
import { IncidentRepository } from '../../repositories/incident.repository';
import { ReportRepository } from '../../repositories/report.repository';

function fakeIncident() {
  const now = new Date('2026-01-01T00:00:00Z');
  return {
    id: 'inc-1',
    type: 'ROBBERY',
    severity: 'MODERATE',
    status: 'ACTIVE',
    lat: -12.06,
    lng: -77.03,
    district: 'Lima',
    confirmCount: 0,
    denyCount: 0,
    reportCount: 3,
    expiresAt: now,
    createdAt: now,
    updatedAt: now,
    unitAssigned: null,
    feedback: null,
    aiScore: null,
    aiVerified: null,
    photoTakenAt: null,
    photoSource: null,
  } as unknown as Awaited<ReturnType<IncidentRepository['findById']>>;
}

function makeRepos(reporterScores: number[]) {
  const incidentRepo = {
    findById: async () => fakeIncident(),
    getStatusHistory: async () => [],
  } as unknown as IncidentRepository;

  const reportRepo = {
    findByIncidentId: async () => [],
    findReporterReputationsByIncidentId: async () => reporterScores,
  } as unknown as ReportRepository;

  return { incidentRepo, reportRepo };
}

describe('getIncidentById — reporterTrust', () => {
  it('attaches the aggregate reporter tier from anonymized scores', async () => {
    const { incidentRepo, reportRepo } = makeRepos([200, 130, 130]); // avg > HIGH
    const dto = await getIncidentById('inc-1', incidentRepo, reportRepo);
    expect(dto.reporterTrust).toBe('high');
  });

  it('is null when there are no reporters with known reputation', async () => {
    const { incidentRepo, reportRepo } = makeRepos([]);
    const dto = await getIncidentById('inc-1', incidentRepo, reportRepo);
    expect(dto.reporterTrust).toBeNull();
  });

  it('never leaks reporter identity in the DTO', async () => {
    const { incidentRepo, reportRepo } = makeRepos([100, 100]);
    const dto = await getIncidentById('inc-1', incidentRepo, reportRepo);
    expect(JSON.stringify(dto)).not.toMatch(/userId|firebaseUid|reputationScore/i);
  });
});
