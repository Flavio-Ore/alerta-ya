export const DISTRICTS = [
  'Barranco', 'Callao', 'Cercado de Lima', 'Comas', 'Jesús María',
  'La Molina', 'La Victoria', 'Los Olivos', 'Lince', 'Magdalena',
  'Miraflores', 'Pueblo Libre', 'San Borja', 'San Isidro',
  'San Juan de Lurigancho', 'San Miguel', 'Santiago de Surco',
  'Surquillo', 'Villa El Salvador', 'Villa María del Triunfo',
];

export const DISTRICT_OPTIONS = ['ALL', ...DISTRICTS];

export const TYPE_OPTIONS = [
  'ALL', 'ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS',
] as const;

export const SEVERITY_OPTIONS = [
  'ALL', 'CRITICAL', 'MODERATE', 'LOW',
] as const;

export const STATUS_OPTIONS = [
  'ALL', 'ACTIVE', 'IN_ATTENTION', 'CLOSED',
] as const;

export const DATE_PRESETS = [
  { label: 'Hoy', value: 'today' },
  { label: 'Ayer', value: 'yesterday' },
  { label: 'Últ. 7 días', value: '7d' },
  { label: 'Últ. 30 días', value: '30d' },
];

export function todayISO(): string {
  return new Date().toISOString().split('T')[0];
}

export function daysAgoISO(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d.toISOString().split('T')[0];
}

export interface FilterSelectOption {
  value: string;
  label: string;
}

export function FilterSelect({
  value,
  onChange,
  options,
  icon,
}: {
  value: string;
  onChange: (v: string) => void;
  options: FilterSelectOption[];
  icon?: string;
}) {
  const isDefault = value === 'ALL';
  return (
    <label className="flex items-center gap-2 text-sm cursor-pointer relative">
      {icon && (
        <span className="material-symbols-outlined text-[18px] text-stitch-outline pointer-events-none">
          {icon}
        </span>
      )}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{ backgroundImage: 'none' }}
        className={`bg-transparent appearance-none pr-6 pl-0 py-0 border-0 outline-none focus:ring-0 cursor-pointer ${
          isDefault ? 'text-stitch-outline' : 'text-white font-semibold'
        }`}
      >
        {options.map((opt) => (
          <option
            key={opt.value}
            value={opt.value}
            className="bg-ay-bg-dark2 text-white"
          >
            {opt.label}
          </option>
        ))}
      </select>
      <span className="material-symbols-outlined text-[18px] text-stitch-outline absolute right-0 pointer-events-none">
        expand_more
      </span>
    </label>
  );
}
