import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';

import { AiBreakdownPanel } from './AiBreakdownPanel';
import type { PublicIncidentDetailDTO } from '../api/types';

function makeIncident(overrides: Partial<PublicIncidentDetailDTO> = {}): PublicIncidentDetailDTO {
  return {
    id: 'inc-1',
    type: 'ROBBERY',
    severity: 'MODERATE',
    status: 'ACTIVE',
    lat: -12.05,
    lng: -77.03,
    district: 'Miraflores',
    confirmCount: 0,
    denyCount: 0,
    reportCount: 1,
    expiresAt: new Date().toISOString(),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    weaponReports: 0,
    injuredReports: 0,
    stillHereReports: 0,
    evidence: [],
    statusHistory: [],
    aiScore: null,
    aiVerified: null,
    photoTakenAt: null,
    photoSource: null,
    ...overrides,
  };
}

describe('AiBreakdownPanel', () => {
  it('GIVEN full AI data THEN shows score %, verdict, has_evidence=true, computed photo_age, visionMatch "no disponible"', () => {
    const tenMinAgo = new Date(Date.now() - 10 * 60_000).toISOString();
    const incident = makeIncident({
      aiScore: 0.72,
      aiVerified: true,
      evidence: [{ formData: {}, mediaUrls: ['gs://bucket/a.jpg', 'gs://bucket/b.jpg'] }],
      photoTakenAt: tenMinAgo,
      photoSource: 'exif',
    });

    render(<AiBreakdownPanel incident={incident} />);

    expect(screen.getAllByText(/72%/).length).toBeGreaterThan(0);
    expect(screen.getByText(/Verificado por IA/i)).toBeInTheDocument();
    expect(screen.getByText(/no disponible/i)).toBeInTheDocument();
    expect(screen.getByText(/hace 10 min/i)).toBeInTheDocument();
  });

  it('GIVEN no AI data at all THEN shows empty-state, has_evidence=false, no crash', () => {
    const incident = makeIncident({
      aiScore: null,
      aiVerified: null,
      evidence: [],
      photoTakenAt: null,
      photoSource: null,
    });

    render(<AiBreakdownPanel incident={incident} />);

    expect(screen.getByText(/Sin datos de IA/i)).toBeInTheDocument();
  });

  it('GIVEN aiScore=null but evidence present THEN renders panel (not empty-state) with "Sin evaluar por IA"', () => {
    const incident = makeIncident({
      aiScore: null,
      aiVerified: null,
      evidence: [{ formData: {}, mediaUrls: ['gs://bucket/a.jpg'] }],
    });

    render(<AiBreakdownPanel incident={incident} />);

    // Not the empty-state — evidence exists, so the full panel shows the AI verdict.
    expect(screen.queryByText(/Sin datos de IA/i)).not.toBeInTheDocument();
    expect(screen.getByText(/Sin evaluar por IA/i)).toBeInTheDocument();
  });

  it('GIVEN photoSource=device_clock THEN photo age is marked "(no verificado)" — mirrors the backend trust gate', () => {
    const tenMinAgo = new Date(Date.now() - 10 * 60_000).toISOString();
    const incident = makeIncident({
      aiScore: 0.6,
      aiVerified: true,
      evidence: [{ formData: {}, mediaUrls: ['gs://bucket/a.jpg'] }],
      photoTakenAt: tenMinAgo,
      photoSource: 'device_clock',
    });

    render(<AiBreakdownPanel incident={incident} />);

    // Not shown as a trusted fresh age — the verifier discounted it (999 sentinel).
    expect(screen.getByText(/no verificado/i)).toBeInTheDocument();
  });

  it('has_evidence is RECOMPUTED from evidence[].mediaUrls.length, not trusted blindly', () => {
    const incident = makeIncident({
      aiScore: 0.5,
      aiVerified: false,
      evidence: [{ formData: {}, mediaUrls: [] }],
    });

    render(<AiBreakdownPanel incident={incident} />);

    // No media anywhere -> has_evidence must read as false ("Sin evidencia adjunta")
    expect(screen.getByText(/Sin evidencia adjunta/i)).toBeInTheDocument();
  });
});
