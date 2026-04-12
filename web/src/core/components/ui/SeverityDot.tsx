import { FC } from 'react';
import { clsx } from 'clsx';

type Severity = 'LOW' | 'MODERATE' | 'CRITICAL';

interface SeverityDotProps {
  severity: Severity;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const SeverityDot: FC<SeverityDotProps> = ({
  severity,
  size = 'md',
  className,
}) => {
  const colorClass = {
    LOW:      'bg-[#22C55E]',
    MODERATE: 'bg-[#F5A623]',
    CRITICAL: 'bg-[#EF4444]',
  }[severity];

  const sizeClass = {
    sm: 'w-2 h-2',
    md: 'w-2.5 h-2.5',
    lg: 'w-3 h-3',
  }[size];

  return (
    <span className={clsx('inline-block rounded-full shrink-0', colorClass, sizeClass, className)} />
  );
};
