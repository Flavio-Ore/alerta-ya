import { FC, ButtonHTMLAttributes } from 'react';
import { clsx } from 'clsx';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'outlined' | 'destructive';
  isLoading?: boolean;
}

/**
 * Botón primario AlertaYa.
 * UI_RULES.md: fondo #1B3A6B, texto #FFFFFF, alto 52px, border-radius 28px,
 * disabled = opacity 0.4, sin sombras.
 */
export const Button: FC<ButtonProps> = ({
  variant = 'primary',
  isLoading = false,
  disabled,
  className,
  children,
  ...props
}) => {
  const base =
    'inline-flex items-center justify-center h-[52px] px-6 text-sm font-bold transition-opacity focus:outline-none focus:ring-2 focus:ring-ay-primary focus:ring-offset-2';

  const variants = {
    primary:
      'bg-ay-primary text-white rounded-btn shadow-none hover:opacity-90',
    outlined:
      'bg-transparent text-ay-primary border border-ay-primary rounded-btn hover:opacity-90',
    destructive:
      'bg-transparent text-ay-critical hover:opacity-90',
  };

  return (
    <button
      className={clsx(base, variants[variant], (disabled || isLoading) && 'opacity-40 cursor-not-allowed', className)}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? (
        <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
      ) : (
        children
      )}
    </button>
  );
};
