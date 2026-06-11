import { useMemo, useState } from 'react';

import { useIncidentsList } from '../../incidents/infrastructure/incidents.api';
import {
  filterForExport,
  generateExport,
  getRecentExports,
  saveRecentExport,
  type ReportFormat,
  type ReportType,
  type RecentExport,
} from '../infrastructure/export.utils';

type DatePreset = 'week' | 'month' | 'quarter' | 'custom';

interface ReportTypeOption {
  id:          ReportType | 'ai_patterns';
  label:       string;
  description: string;
  disabled?:   boolean;
  reason?:     string;
}

const REPORT_TYPES: ReportTypeOption[] = [
  { id: 'executive',     label: 'Resumen Ejecutivo',      description: 'KPIs agregados + distribución por tipo.' },
  { id: 'detail',        label: 'Detalle por Incidente',  description: 'Tabla con todos los incidentes del período.' },
  { id: 'ai_patterns',   label: 'Análisis de Patrones IA', description: 'Detección de patrones recurrentes.', disabled: true, reason: 'Requiere ML service' },
  { id: 'form_responses', label: 'Respuestas del Formulario', description: 'Datos brutos del formulario por incidente.' },
];

function presetRange(preset: DatePreset): { from: Date; to: Date } | null {
  if (preset === 'custom') return null;
  const to = new Date();
  to.setHours(23, 59, 59, 999);
  const from = new Date(to);
  if (preset === 'week')    from.setDate(from.getDate() - 7);
  if (preset === 'month')   from.setDate(from.getDate() - 30);
  if (preset === 'quarter') from.setDate(from.getDate() - 90);
  from.setHours(0, 0, 0, 0);
  return { from, to };
}

function toInputDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export default function ExportPage() {
  // status:'ALL' es CRÍTICO acá — el export debe poder incluir cerrados, en atención,
  // expirados. Si no pasamos 'ALL', el backend devuelve solo ACTIVE (default móvil).
  const { data, isLoading } = useIncidentsList({ pageSize: 100, status: 'ALL' });

  const [reportType, setReportType] = useState<ReportType>('executive');
  const [format, setFormat] = useState<ReportFormat>('pdf');
  const [datePreset, setDatePreset] = useState<DatePreset>('month');
  const [from, setFrom] = useState<string>(() => toInputDate(presetRange('month')!.from));
  const [to, setTo]     = useState<string>(() => toInputDate(presetRange('month')!.to));
  const [districts, setDistricts] = useState<string[]>([]);
  const [onlyWithFeedback, setOnlyWithFeedback] = useState(false);
  const [recent, setRecent] = useState<RecentExport[]>(() => getRecentExports());
  const [generating, setGenerating] = useState(false);

  function applyPreset(preset: DatePreset) {
    setDatePreset(preset);
    const range = presetRange(preset);
    if (range) {
      setFrom(toInputDate(range.from));
      setTo(toInputDate(range.to));
    }
  }

  const availableDistricts = useMemo(() => {
    const set = new Set((data?.items ?? []).map((i) => i.district));
    return Array.from(set).sort();
  }, [data]);

  const filteredCount = useMemo(() => {
    if (!data) return 0;
    return filterForExport(data.items, {
      from:             new Date(from),
      to:               new Date(`${to}T23:59:59`),
      districts,
      onlyWithFeedback,
    }).length;
  }, [data, from, to, districts, onlyWithFeedback]);

  function toggleDistrict(d: string) {
    setDistricts((prev) => (prev.includes(d) ? prev.filter((x) => x !== d) : [...prev, d]));
  }

  async function handleGenerate() {
    if (!data) return;
    setGenerating(true);
    try {
      const filters = {
        from:             new Date(from),
        to:               new Date(`${to}T23:59:59`),
        districts,
        onlyWithFeedback,
      };
      const incidents = filterForExport(data.items, filters);
      const result = await generateExport(incidents, filters, format, reportType);
      const updated = saveRecentExport({
        filename: result.filename,
        format,
        type:     reportType,
        sizeKb:   result.sizeKb,
        ts:       new Date().toISOString(),
      });
      setRecent(updated);
    } finally {
      setGenerating(false);
    }
  }

  return (
    <div className="flex-1 overflow-auto bg-ay-bg-dark text-stitch-on-surface">
      <div className="max-w-[1440px] mx-auto px-10 py-10">
        {/* Header */}
        <div className="mb-10">
          <h1 className="text-2xl font-bold text-white font-headline mb-2">
            Exportar Reportes Estadísticos
          </h1>
          <div className="flex items-center gap-2 text-ay-text-sec text-[13px]">
            <span className="material-symbols-outlined text-base">lock</span>
            <p>
              Todos los reportes son anónimos. No incluyen datos personales. Cumplimiento Ley N°
              29733.
            </p>
          </div>
        </div>

        <div className="flex gap-8 flex-wrap lg:flex-nowrap">
          {/* Columna izquierda: configuración (55%) */}
          <section className="w-full lg:w-[55%] flex flex-col gap-6">
            {/* Tipo de reporte */}
            <Card title="Tipo de reporte">
              <div className="grid grid-cols-2 gap-4">
                {REPORT_TYPES.map((opt) => (
                  <ReportTypeCard
                    key={opt.id}
                    option={opt}
                    selected={opt.id === reportType}
                    onSelect={() => !opt.disabled && setReportType(opt.id as ReportType)}
                  />
                ))}
              </div>
            </Card>

            {/* Período */}
            <Card title="Período">
              <div className="flex justify-end gap-2 mb-5 flex-wrap">
                {(['week', 'month', 'quarter', 'custom'] as DatePreset[]).map((preset) => (
                  <button
                    key={preset}
                    onClick={() => applyPreset(preset)}
                    className={`px-3 py-1 rounded-full text-[11px] font-bold uppercase transition-colors ${
                      datePreset === preset
                        ? 'bg-stitch-primary-container text-white'
                        : 'bg-stitch-surface-container-low text-ay-text-sec hover:text-white'
                    }`}
                  >
                    {preset === 'week' && 'Esta semana'}
                    {preset === 'month' && 'Este mes'}
                    {preset === 'quarter' && 'Último trimestre'}
                    {preset === 'custom' && 'Personalizado'}
                  </button>
                ))}
              </div>
              <div className="grid grid-cols-2 gap-6">
                <DateInput
                  label="Desde"
                  value={from}
                  onChange={(v) => {
                    setFrom(v);
                    setDatePreset('custom');
                  }}
                />
                <DateInput
                  label="Hasta"
                  value={to}
                  onChange={(v) => {
                    setTo(v);
                    setDatePreset('custom');
                  }}
                />
              </div>
            </Card>

            {/* Filtros */}
            <Card title="Filtros opcionales">
              <div className="mb-6">
                <label className="text-[10px] font-bold text-ay-text-sec uppercase block mb-3">
                  Distritos
                </label>
                <div className="flex flex-wrap gap-2">
                  {districts.map((d) => (
                    <button
                      key={d}
                      onClick={() => toggleDistrict(d)}
                      className="flex items-center gap-2 px-3 py-1.5 bg-stitch-primary-container/40 border border-stitch-primary-container text-white text-xs rounded-full hover:bg-stitch-primary-container/60"
                    >
                      {d}
                      <span className="material-symbols-outlined text-xs">close</span>
                    </button>
                  ))}

                  <DistrictPicker
                    options={availableDistricts.filter((d) => !districts.includes(d))}
                    onPick={toggleDistrict}
                  />
                </div>
                {availableDistricts.length === 0 && !isLoading && (
                  <p className="text-[11px] text-ay-text-sec mt-3">
                    No hay distritos disponibles. Cargá data con el seed primero.
                  </p>
                )}
              </div>

              <div className="space-y-4">
                <CheckboxRow
                  label="Solo incidentes con feedback de autoridad"
                  checked={onlyWithFeedback}
                  onChange={setOnlyWithFeedback}
                />
                <CheckboxRow
                  label="Incluir gráficas estadísticas (en PDF Resumen Ejecutivo)"
                  checked
                  disabled
                  hint="Incluido por defecto en Resumen Ejecutivo"
                />
                <CheckboxRow
                  label="Incluir mapa de calor geolocalizado"
                  checked={false}
                  disabled
                  hint="Próximamente — requiere generación server-side"
                />
              </div>
            </Card>

            {/* Formato */}
            <Card title="Formato de exportación">
              <div className="flex gap-4">
                <FormatButton
                  selected={format === 'pdf'}
                  onClick={() => setFormat('pdf')}
                  icon="picture_as_pdf"
                  title="PDF"
                  subtitle="Para MININTER"
                />
                <FormatButton
                  selected={format === 'xlsx'}
                  onClick={() => setFormat('xlsx')}
                  icon="table_view"
                  title="Excel"
                  subtitle="Análisis avanzado"
                />
              </div>
            </Card>

            {/* Generar */}
            <button
              disabled={generating || isLoading || filteredCount === 0}
              onClick={handleGenerate}
              className="w-full h-[52px] bg-stitch-primary-container text-white font-bold rounded-[10px] hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span className="material-symbols-outlined">
                {generating ? 'hourglass_empty' : 'file_download'}
              </span>
              {generating
                ? 'Generando…'
                : filteredCount === 0
                  ? 'Sin incidentes en el período seleccionado'
                  : `Generar Reporte (${filteredCount} ${filteredCount === 1 ? 'incidente' : 'incidentes'})`}
            </button>
          </section>

          {/* Columna derecha: preview + recientes (45%) */}
          <aside className="w-full lg:w-[45%] flex flex-col gap-6">
            {/* Preview */}
            <Card
              title="Vista previa del reporte"
              badge={
                <span className="px-3 py-1 bg-stitch-primary-container/20 text-stitch-primary text-[10px] font-bold uppercase rounded">
                  {format.toUpperCase()} · {REPORT_TYPES.find((r) => r.id === reportType)?.label}
                </span>
              }
            >
              <ReportPreview
                count={filteredCount}
                from={from}
                to={to}
                format={format}
              />
            </Card>

            {/* Últimas exportaciones */}
            <Card title="Últimas exportaciones">
              {recent.length === 0 ? (
                <p className="text-xs text-ay-text-sec">
                  Aún no generaste ningún reporte. Las últimas 5 aparecerán acá.
                </p>
              ) : (
                <div className="flex flex-col gap-2">
                  {recent.map((r) => (
                    <div
                      key={r.ts}
                      className="flex items-center justify-between p-3 bg-stitch-surface-container-low rounded-lg"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <span className="material-symbols-outlined text-ay-text-sec shrink-0">
                          {r.format === 'pdf' ? 'description' : 'grid_on'}
                        </span>
                        <div className="min-w-0">
                          <p className="text-xs font-bold text-white truncate">{r.filename}</p>
                          <p className="text-[10px] text-ay-text-sec">
                            {new Date(r.ts).toLocaleString('es-PE')} · {r.sizeKb} KB
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          </aside>
        </div>
      </div>
    </div>
  );
}

// ── Subcomponentes ───────────────────────────────────────────────────────────
function Card({
  title,
  badge,
  children,
}: {
  title: string;
  badge?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-ay-bg-dark2 rounded-[12px] border border-ay-border p-6">
      <div className="flex justify-between items-center mb-5">
        <h3 className="text-sm font-bold text-white uppercase tracking-wide">{title}</h3>
        {badge}
      </div>
      {children}
    </div>
  );
}

function ReportTypeCard({
  option,
  selected,
  onSelect,
}: {
  option:   ReportTypeOption;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <label
      onClick={onSelect}
      className={`flex flex-col gap-2 p-4 rounded-lg cursor-pointer transition-colors ${
        option.disabled
          ? 'bg-stitch-surface-container-low/50 cursor-not-allowed opacity-50'
          : selected
            ? 'bg-stitch-surface-container border border-stitch-primary-container'
            : 'bg-stitch-surface-container-low border border-transparent hover:bg-stitch-surface-container-highest'
      }`}
      title={option.reason}
    >
      <div className="flex items-center gap-3">
        <input
          type="radio"
          checked={selected}
          onChange={onSelect}
          disabled={option.disabled}
          className="text-stitch-tertiary focus:ring-0 bg-transparent border-stitch-outline"
        />
        <span className={`text-sm font-medium ${selected ? 'text-white' : 'text-ay-text-muted'}`}>
          {option.label}
        </span>
      </div>
      <p className="text-[11px] text-ay-text-sec pl-7">{option.description}</p>
      {option.reason && (
        <span className="text-[9px] font-bold uppercase tracking-widest text-stitch-tertiary pl-7">
          {option.reason}
        </span>
      )}
    </label>
  );
}

function DateInput({
  label,
  value,
  onChange,
}: {
  label:    string;
  value:    string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="space-y-2">
      <label className="text-[10px] font-bold text-ay-text-sec uppercase">{label}</label>
      <div className="flex items-center gap-3 p-3 bg-stitch-surface-container-low rounded-lg">
        <span className="material-symbols-outlined text-ay-text-sec text-sm">calendar_today</span>
        <input
          type="date"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="bg-transparent text-sm text-white outline-none border-0 p-0 focus:ring-0 [color-scheme:dark]"
        />
      </div>
    </div>
  );
}

function DistrictPicker({
  options,
  onPick,
}: {
  options: string[];
  onPick: (d: string) => void;
}) {
  const [open, setOpen] = useState(false);
  if (options.length === 0) return null;

  return (
    <div className="relative">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex items-center gap-1 px-3 py-1.5 border border-dashed border-stitch-outline/50 text-ay-text-sec text-xs rounded-full hover:border-stitch-outline hover:text-stitch-on-surface transition-all"
      >
        <span className="material-symbols-outlined text-xs">add</span> Añadir
      </button>
      {open && (
        <div className="absolute top-full left-0 mt-2 bg-stitch-surface-container-high rounded-lg p-2 z-10 max-h-60 overflow-auto min-w-[180px] shadow-xl">
          {options.map((d) => (
            <button
              key={d}
              onClick={() => {
                onPick(d);
                setOpen(false);
              }}
              className="w-full text-left px-3 py-2 text-xs text-stitch-on-surface hover:bg-stitch-surface-container-highest rounded transition-colors"
            >
              {d}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function CheckboxRow({
  label,
  checked,
  onChange,
  disabled,
  hint,
}: {
  label:     string;
  checked:   boolean;
  onChange?: (v: boolean) => void;
  disabled?: boolean;
  hint?:     string;
}) {
  return (
    <label
      className={`flex items-start gap-3 cursor-pointer ${
        disabled ? 'opacity-60 cursor-not-allowed' : ''
      }`}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => !disabled && onChange?.(e.target.checked)}
        disabled={disabled}
        className="w-4 h-4 mt-0.5 rounded bg-transparent border-stitch-outline text-stitch-primary-container focus:ring-0"
      />
      <div className="flex flex-col">
        <span className="text-sm text-ay-text-muted">{label}</span>
        {hint && <span className="text-[10px] text-ay-text-sec mt-0.5">{hint}</span>}
      </div>
    </label>
  );
}

function FormatButton({
  selected,
  onClick,
  icon,
  title,
  subtitle,
}: {
  selected: boolean;
  onClick:  () => void;
  icon:     string;
  title:    string;
  subtitle: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex-1 flex flex-col items-center gap-2 p-5 rounded-xl transition-all ${
        selected
          ? 'bg-stitch-primary-container border-2 border-stitch-primary text-white'
          : 'bg-stitch-surface-container-low border border-transparent text-ay-text-sec hover:bg-stitch-surface-container-high'
      }`}
    >
      <span
        className="material-symbols-outlined text-2xl"
        style={{ fontVariationSettings: selected ? "'FILL' 1" : "'FILL' 0" }}
      >
        {icon}
      </span>
      <div className="text-center">
        <div className="font-bold text-sm">{title}</div>
        <div className="text-[10px] opacity-80">{subtitle}</div>
      </div>
    </button>
  );
}

function ReportPreview({
  count,
  from,
  to,
  format,
}: {
  count:  number;
  from:   string;
  to:     string;
  format: ReportFormat;
}) {
  return (
    <div className="aspect-[1/1.4] bg-white rounded-sm shadow-xl overflow-hidden p-6 flex flex-col text-stitch-surface">
      {/* PDF Header */}
      <div className="flex justify-between items-start mb-6">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 bg-stitch-primary-container flex items-center justify-center rounded">
            <span
              className="material-symbols-outlined text-white text-base"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              security
            </span>
          </div>
          <span className="font-bold text-[10px] tracking-tighter text-stitch-primary-container">
            ALERTAYA
          </span>
        </div>
        <div className="text-[8px] text-right text-gray-400">
          Documento ID: #AYA-{Date.now().toString(36).toUpperCase().slice(-8)}
          <br />
          Emitido: {new Date().toLocaleString('es-PE', { dateStyle: 'short' })}
        </div>
      </div>

      <h4 className="text-lg font-black uppercase mb-1">REPORTE ESTADÍSTICO</h4>
      <p className="text-[10px] text-gray-500 mb-6 pb-3 border-b border-gray-200">
        Inteligencia de Datos & Análisis de Seguridad Ciudadana — Lima
      </p>

      <div className="grid grid-cols-2 gap-6 mb-6">
        <div>
          <p className="text-[7px] font-bold text-gray-400 uppercase mb-1">Período</p>
          <p className="text-[10px] font-bold text-gray-800">
            {new Date(from).toLocaleDateString('es-PE')} —{' '}
            {new Date(to).toLocaleDateString('es-PE')}
          </p>
        </div>
        <div>
          <p className="text-[7px] font-bold text-gray-400 uppercase mb-1">Formato</p>
          <p className="text-[10px] font-bold text-gray-800">{format.toUpperCase()}</p>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-2 mb-6">
        <div className="p-2 bg-gray-50 rounded border border-gray-100">
          <p className="text-[6px] font-bold text-gray-400 mb-0.5">INCIDENTES</p>
          <p className="text-sm font-bold text-stitch-primary-container">{count}</p>
        </div>
        <div className="p-2 bg-gray-50 rounded border border-gray-100">
          <p className="text-[6px] font-bold text-gray-400 mb-0.5">PÁGINAS</p>
          <p className="text-sm font-bold text-stitch-primary-container">
            {Math.max(1, Math.ceil(count / 25))}
          </p>
        </div>
        <div className="p-2 bg-gray-50 rounded border border-gray-100">
          <p className="text-[6px] font-bold text-gray-400 mb-0.5">CONFIDENCIAL</p>
          <p className="text-sm font-bold text-green-600">SÍ</p>
        </div>
      </div>

      <div className="flex-grow bg-gray-50 rounded border border-gray-100 flex items-end p-3 gap-1.5">
        {[40, 60, 75, 90, 70, 50].map((h, i) => (
          <div
            key={i}
            className="w-full rounded-t-sm"
            style={{
              height:          `${h}%`,
              backgroundColor: i === 3 ? '#1B3A6B' : i === 4 ? '#F5A623' : 'rgba(27,58,107,0.4)',
            }}
          />
        ))}
      </div>

      <div className="mt-4 pt-3 border-t-2 border-stitch-primary-container flex justify-between items-center">
        <p className="text-[7px] font-bold text-stitch-primary-container">CONFIDENCIAL</p>
        <p className="text-[7px] text-gray-400">Vista previa</p>
      </div>
    </div>
  );
}
