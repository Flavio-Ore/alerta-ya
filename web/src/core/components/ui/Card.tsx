import { FC, HTMLAttributes } from 'react';
import { clsx } from 'clsx';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'light' | 'dark';
}

/**
 * Card base AlertaYa.
 * UI_RULES.md: sin sombras, border sutil.
 * light: fondo #FFFFFF, borde #E2E8F0, radius 14px
 * dark:  fondo #141720, borde #2D3A4A, radius 12px
 */
export const Card: FC<CardProps> = ({ variant = 'dark', className, children, ...props }) => {
  const variants = {
    light: 'bg-white border border-[#E2E8F0] rounded-[14px]',
    dark:  'bg-ay-bg-dark2 rounded-[12px]',
  };

  return (
    <div
      className={clsx('p-4', variants[variant], className)}
      style={variant === 'dark' ? { border: '0.5px solid #2D3A4A' } : undefined}
      {...props}
    >
      {children}
    </div>
  );
};
