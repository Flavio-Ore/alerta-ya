import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'Barlow', 'Nunito Sans', 'Arial', 'sans-serif'],
      },
      colors: {
        // ── Tokens de marca AlertaYa ─────────────────────────────────────
        'ay-primary':    '#1B3A6B',
        'ay-accent':     '#F5A623',
        'ay-dark':       '#0D1B2A',
        'ay-bg-light':   '#FFFFFF',
        'ay-bg-gray':    '#F4F6F9',
        'ay-bg-dark':    '#1A1D23',
        'ay-bg-dark2':   '#141720',
        'ay-low':        '#22C55E',
        'ay-moderate':   '#F5A623',
        'ay-critical':   '#EF4444',
        'ay-text-pri':   '#0D1B2A',
        'ay-text-sec':   '#6B7A8D',
        'ay-text-muted': '#C4CDD8',
        'ay-border':     '#2D3A4A',

        // ── shadcn/ui CSS variable tokens (dark dashboard theme) ─────────
        border:      'hsl(var(--border))',
        input:       'hsl(var(--input))',
        ring:        'hsl(var(--ring))',
        background:  'hsl(var(--background))',
        foreground:  'hsl(var(--foreground))',
        primary: {
          DEFAULT:    'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT:    'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT:    'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT:    'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT:    'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT:    'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT:    'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg:        'var(--radius)',
        md:        'calc(var(--radius) - 2px)',
        sm:        'calc(var(--radius) - 4px)',
        // Tokens propios
        pill:      '100px',
        btn:       '28px',
        card:      '14px',
        'card-sm': '12px',
        input:     '10px',
      },
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to:   { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to:   { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up':   'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('tailwindcss-animate')],
};

export default config;
