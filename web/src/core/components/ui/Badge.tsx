import { FC } from 'react';
import { clsx } from 'clsx';

type Severity = 'LOW' | 'MODERATE' | 'CRITICAL';

interface BadgeProps {
  severity: Severity;
  className?: string;
}

/**
 * Badge de severidad.
 * Specs UI_RULES.md: pill, 11px bold, dot 7px a la izquierda.
 */
export const Badge: FC<BadgeProps> = ({ severity, className }) => {
  const config = {
    LOW: {
      label: 'LEVE',
      containerClass: 'bg-[#DCFCE7] border border-[#22C55E44] text-[#15803D]',
      dotClass: 'bg-[#22C55E]',
    },
    MODERATE: {
      label: 'MODERADO',
      containerClass: 'bg-[#FEF9C3] border border-[#F5A62344] text-[#854D0E]',
      dotClass: 'bg-[#F5A623]',
    },
    CRITICAL: {
      label: 'CRÍTICO',
      containerClass: 'bg-[#FEE2E2] border border-[#EF444444] text-[#991B1B]',
      dotClass: 'bg-[#EF4444]',
    },
  }[severity];

  return (
    <span
      className={clsx(
        'inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold',
        config.containerClass,
        className,
      )}
    >
      <span className={clsx('w-[7px] h-[7px] rounded-full shrink-0', config.dotClass)} />
      {config.label}
    </span>
  );
};
