/**
 * get-my-reports.usecase — AI fields (aiScore/aiVerified) unit tests
 *
 * Verifies MyReportIncidentDTO exposes aiScore/aiVerified (PR1c, ai-metric-ux)
 * and that reporter identity fields are never leaked.
 */
import { describe, it, expect, vi } from 'vitest';

import type { Incident, Report, IncidentType, Severity, IncidentStatus } from '@prisma/client';

import { getMyReports } from '../get-my-reports.usecase';
import type { ReportRepository, ReportWithIncident } from '../../repositories/report.repository';

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
    feedback: null,
    aiScore: null,
    aiVerified: null,
    expiresAt: now,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  } as Incident;
}

function makeReport(overrides: Partial<ReportWithIncident> = {}): ReportWithIncident {
  const now = new Date();
  return {
    id: 'report-1',
    userId: 'user-1',
    lat: -12.1167,
    lng: -77.0372,
    formData: {},
    mediaUrls: [],
    incidentId: 'incident-1',
    photoTakenAt: null,
    photoSource: null,
    createdAt: now,
    incident: makeIncident(),
    ...overrides,
  } as ReportWithIncident;
}

function makeRepo(items: ReportWithIncident[]): ReportRepository {
  return {
    create: vi.fn(),
    findOrphanedNearby: vi.fn(),
    findByIncidentId: vi.fn(),
    findByUserId: vi.fn().mockResolvedValue({ items, total: items.length }),
    findFirebaseUidsByIncidentId: vi.fn(),
    cancelReport: vi.fn(),
  };
}

describe('getMyReports — AI fields', () => {
  it('maps aiScore/aiVerified when the verifier ran and marked the report verified', async () => {
    const report = makeReport({
      incident: makeIncident({ aiScore: 0.85, aiVerified: true }),
    });
    const repo = makeRepo([report]);

    const result = await getMyReports({ userId: 'user-1', page: 1, pageSize: 10 }, repo);

    expect(result.items[0].incident?.aiScore).toBe(0.85);
    expect(result.items[0].incident?.aiVerified).toBe(true);
  });

  it('maps aiScore/aiVerified when the verifier ran and flagged the report suspicious', async () => {
    const report = makeReport({
      incident: makeIncident({ aiScore: 0.2, aiVerified: false }),
    });
    const repo = makeRepo([report]);

    const result = await getMyReports({ userId: 'user-1', page: 1, pageSize: 10 }, repo);

    expect(result.items[0].incident?.aiScore).toBe(0.2);
    expect(result.items[0].incident?.aiVerified).toBe(false);
  });

  it('returns null aiScore/aiVerified when the verifier never ran', async () => {
    const report = makeReport({
      incident: makeIncident({ aiScore: null, aiVerified: null }),
    });
    const repo = makeRepo([report]);

    const result = await getMyReports({ userId: 'user-1', page: 1, pageSize: 10 }, repo);

    expect(result.items[0].incident?.aiScore).toBeNull();
    expect(result.items[0].incident?.aiVerified).toBeNull();
  });

  it('never exposes reporter identity fields on the incident DTO', async () => {
    const report = makeReport({
      incident: makeIncident({ aiScore: 0.9, aiVerified: true }),
    });
    const repo = makeRepo([report]);

    const result = await getMyReports({ userId: 'user-1', page: 1, pageSize: 10 }, repo);

    const incidentDto = result.items[0].incident as Record<string, unknown> | null;
    expect(incidentDto).not.toBeNull();
    expect(incidentDto).not.toHaveProperty('userId');
    expect(incidentDto).not.toHaveProperty('email');
    expect(incidentDto).not.toHaveProperty('name');
    expect(incidentDto).not.toHaveProperty('firebaseUid');
  });

  it('returns null incident DTO when the report has no linked incident (orphan)', async () => {
    const report = makeReport({ incidentId: null, incident: null });
    const repo = makeRepo([report]);

    const result = await getMyReports({ userId: 'user-1', page: 1, pageSize: 10 }, repo);

    expect(result.items[0].incident).toBeNull();
  });
});
