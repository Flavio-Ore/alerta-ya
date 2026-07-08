import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';

import { AiConfidenceBadge } from './AiConfidenceBadge';

describe('AiConfidenceBadge', () => {
  it('GIVEN verified=true THEN shows "Verificado por IA" state', () => {
    render(<AiConfidenceBadge score={0.9} verified={true} />);
    expect(screen.getByText(/Verificado por IA/i)).toBeInTheDocument();
  });

  it('GIVEN verified=false THEN shows "Sospechoso — revisar" state', () => {
    render(<AiConfidenceBadge score={0.3} verified={false} />);
    expect(screen.getByText(/Sospechoso/i)).toBeInTheDocument();
  });

  it('GIVEN score=null AND verified=null THEN shows "Sin evaluar por IA" state', () => {
    render(<AiConfidenceBadge score={null} verified={null} />);
    expect(screen.getByText(/Sin evaluar por IA/i)).toBeInTheDocument();
  });

  it('REGRESSION GUARD: GIVEN score present AND verified=null THEN must NOT render as verified', () => {
    render(<AiConfidenceBadge score={0.5} verified={null} />);
    expect(screen.queryByText(/Verificado por IA/i)).not.toBeInTheDocument();
    expect(screen.getByText(/Sin evaluar por IA/i)).toBeInTheDocument();
  });

  it('suspicious state uses the dedicated ay-warn token, NOT ay-moderate amber', () => {
    render(<AiConfidenceBadge score={0.3} verified={false} />);
    const badge = screen.getByText(/Sospechoso/i).closest('span');
    expect(badge?.className).toMatch(/ay-warn/);
    expect(badge?.className).not.toMatch(/ay-moderate/);
  });
});
