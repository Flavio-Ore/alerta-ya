import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';

import { EvidenceCarousel } from './EvidenceCarousel';
import { useIncidentEvidence } from '../infrastructure/incidents.api';

vi.mock('../infrastructure/incidents.api', () => ({
  useIncidentEvidence: vi.fn(),
}));

const mockHook = vi.mocked(useIncidentEvidence);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function hookState(partial: Record<string, unknown>): any {
  return { data: undefined, isLoading: false, isError: false, ...partial };
}

describe('EvidenceCarousel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN loading THEN shows a loading state (never blank)', () => {
    mockHook.mockReturnValue(hookState({ isLoading: true }));
    render(<EvidenceCarousel incidentId="inc-1" />);
    expect(screen.getByText(/Cargando evidencia/i)).toBeInTheDocument();
  });

  it('GIVEN error THEN shows an error state (never blank)', () => {
    mockHook.mockReturnValue(hookState({ isError: true }));
    render(<EvidenceCarousel incidentId="inc-1" />);
    expect(screen.getByText(/No se pudo cargar la evidencia/i)).toBeInTheDocument();
  });

  it('GIVEN empty evidence THEN shows "sin pruebas visuales" (never blank)', () => {
    mockHook.mockReturnValue(hookState({ data: { evidence: [] } }));
    render(<EvidenceCarousel incidentId="inc-1" />);
    expect(screen.getByText(/Sin pruebas visuales/i)).toBeInTheDocument();
  });

  it('GIVEN image + video evidence THEN renders both from signed URLs', () => {
    mockHook.mockReturnValue(
      hookState({
        data: {
          evidence: [
            { signedUrl: 'https://signed/a.jpg', kind: 'image' },
            { signedUrl: 'https://signed/b.mp4', kind: 'video' },
          ],
        },
      }),
    );
    render(<EvidenceCarousel incidentId="inc-1" />);

    const img = screen.getByRole('img', { name: /Prueba 1/i });
    expect(img).toHaveAttribute('src', 'https://signed/a.jpg');
    // video has no implicit role; assert count via the src on a video element
    const video = document.querySelector('video');
    expect(video).toHaveAttribute('src', 'https://signed/b.mp4');
    expect(screen.getByText(/Pruebas adjuntas \(2\)/i)).toBeInTheDocument();
  });
});
