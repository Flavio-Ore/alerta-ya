import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

import type { PublicIncidentDTO } from '../../../core/api/types';
import {
  incidentTypeLabel,
  severityLabel,
  statusLabel,
} from '../../incidents/presentation/utils/labels';

export type ReportFormat = 'pdf' | 'xlsx';
export type ReportType   = 'executive' | 'detail' | 'form_responses';

// ── Carga el logo SVG y lo convierte a PNG dataURL para embedearlo en jspdf ──
// Variante "light" (azules originales) para fondo blanco del PDF.
const LOGO_URL = '/assets/logo/alertaya-logo-horizontal.svg';
let cachedLogo: { dataUrl: string; width: number; height: number } | null = null;

async function loadLogoForPdf(): Promise<typeof cachedLogo> {
  if (cachedLogo) return cachedLogo;

  try {
    const res = await fetch(LOGO_URL);
    if (!res.ok) return null;
    const svgText = await res.text();
    const svgBlob = new Blob([svgText], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(svgBlob);

    const img = await new Promise<HTMLImageElement>((resolve, reject) => {
      const i = new Image();
      i.onload = () => resolve(i);
      i.onerror = reject;
      i.src = url;
    });

    // Render a canvas a alta resolución para que se vea nítido en PDF
    const targetWidth  = 600;
    const ratio = img.height / img.width;
    const targetHeight = Math.round(targetWidth * ratio);

    const canvas = document.createElement('canvas');
    canvas.width  = targetWidth;
    canvas.height = targetHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      URL.revokeObjectURL(url);
      return null;
    }
    ctx.drawImage(img, 0, 0, targetWidth, targetHeight);
    URL.revokeObjectURL(url);

    cachedLogo = {
      dataUrl: canvas.toDataURL('image/png'),
      width:   targetWidth,
      height:  targetHeight,
    };
    return cachedLogo;
  } catch {
    return null;
  }
}

export interface RecentExport {
  filename: string;
  format:   ReportFormat;
  type:     ReportType;
  sizeKb:   number;
  ts:       string;
}

const RECENT_KEY = 'alertaya:recent-exports';

// ── Filtros aplicables a los datos antes de exportar ──────────────────────────
export interface ExportFilters {
  from:               Date;
  to:                 Date;
  districts:          string[];           // vacío = todos
  onlyWithFeedback:   boolean;
}

export function filterForExport(
  incidents: PublicIncidentDTO[],
  filters: ExportFilters,
): PublicIncidentDTO[] {
  return incidents.filter((i) => {
    const created = new Date(i.createdAt).getTime();
    if (created < filters.from.getTime() || created > filters.to.getTime()) return false;
    if (filters.districts.length > 0 && !filters.districts.includes(i.district)) return false;
    if (filters.onlyWithFeedback && !i.feedback) return false;
    return true;
  });
}

// ── PDF — Resumen ejecutivo ───────────────────────────────────────────────────
async function buildExecutivePdf(
  incidents: PublicIncidentDTO[],
  filters: ExportFilters,
): Promise<jsPDF> {
  const doc = new jsPDF({ unit: 'pt', format: 'a4' });

  // Header con logo real (fallback a "ALERTAYA" si no carga)
  const logo = await loadLogoForPdf();
  if (logo) {
    const logoHeight = 28;
    const logoWidth  = (logo.width / logo.height) * logoHeight;
    doc.addImage(logo.dataUrl, 'PNG', 40, 38, logoWidth, logoHeight);
  } else {
    doc.setFillColor(27, 58, 107);
    doc.rect(40, 40, 24, 24, 'F');
    doc.setTextColor(27, 58, 107);
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.text('ALERTAYA', 72, 56);
  }

  doc.setFontSize(8);
  doc.setTextColor(120);
  doc.setFont('helvetica', 'normal');
  const docId = `Documento ID: #AYA-${Date.now().toString(36).toUpperCase()}`;
  const emitted = `Emitido: ${new Date().toLocaleString('es-PE')}`;
  doc.text(docId, 555, 50, { align: 'right' });
  doc.text(emitted, 555, 62, { align: 'right' });

  // Title
  doc.setFontSize(18);
  doc.setTextColor(13, 27, 42);
  doc.setFont('helvetica', 'bold');
  doc.text('REPORTE ESTADÍSTICO', 40, 110);

  doc.setFontSize(9);
  doc.setTextColor(120);
  doc.setFont('helvetica', 'normal');
  doc.text('Inteligencia de Datos & Análisis de Seguridad Ciudadana — Lima', 40, 125);

  // Period + recipient
  doc.setDrawColor(230);
  doc.line(40, 140, 555, 140);

  doc.setFontSize(7);
  doc.setTextColor(150);
  doc.setFont('helvetica', 'bold');
  doc.text('PERÍODO DE ANÁLISIS', 40, 160);
  doc.text('FILTROS APLICADOS', 300, 160);

  doc.setFontSize(10);
  doc.setTextColor(40);
  doc.text(
    `${filters.from.toLocaleDateString('es-PE')} — ${filters.to.toLocaleDateString('es-PE')}`,
    40,
    178,
  );
  const filterStr =
    (filters.districts.length === 0 ? 'Todos los distritos' : filters.districts.join(', ')) +
    (filters.onlyWithFeedback ? ' · Solo con feedback' : '');
  doc.text(filterStr, 300, 178);

  // Stats
  const total    = incidents.length;
  const critical = incidents.filter((i) => i.severity === 'CRITICAL').length;
  const closed   = incidents.filter((i) => i.status === 'CLOSED').length;
  const resolution = total > 0 ? Math.round((closed / total) * 100) : 0;

  const cards: Array<[string, string, [number, number, number]]> = [
    ['INCIDENTES',    String(total),         [27, 58, 107]],
    ['CRÍTICOS',      String(critical),      [239, 68, 68]],
    ['RESOLUCIÓN',    `${resolution}%`,      [34, 197, 94]],
  ];
  cards.forEach((card, idx) => {
    const x = 40 + idx * 175;
    doc.setFillColor(245, 247, 250);
    doc.roundedRect(x, 210, 165, 60, 4, 4, 'F');
    doc.setFontSize(7);
    doc.setTextColor(140);
    doc.setFont('helvetica', 'bold');
    doc.text(card[0], x + 14, 230);
    doc.setFontSize(20);
    doc.setTextColor(...card[2]);
    doc.text(card[1], x + 14, 258);
  });

  // Breakdown por tipo
  doc.setFontSize(11);
  doc.setTextColor(13, 27, 42);
  doc.setFont('helvetica', 'bold');
  doc.text('Distribución por tipo de incidente', 40, 310);

  const byType: Record<string, number> = {};
  incidents.forEach((i) => {
    const label = incidentTypeLabel[i.type];
    byType[label] = (byType[label] ?? 0) + 1;
  });

  autoTable(doc, {
    startY: 320,
    head:   [['Tipo', 'Total', '% del período']],
    body:   Object.entries(byType).map(([type, count]) => [
      type,
      count,
      `${total > 0 ? Math.round((count / total) * 100) : 0}%`,
    ]),
    styles:    { fontSize: 9 },
    headStyles: { fillColor: [27, 58, 107], textColor: 255 },
    alternateRowStyles: { fillColor: [248, 250, 252] },
    margin: { left: 40, right: 40 },
  });

  // Confidentiality footer
  const lastY = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY;
  doc.setDrawColor(27, 58, 107);
  doc.setLineWidth(2);
  doc.line(40, lastY + 30, 555, lastY + 30);
  doc.setFontSize(7);
  doc.setTextColor(27, 58, 107);
  doc.setFont('helvetica', 'bold');
  doc.text('CONFIDENCIAL · SOLO USO INSTITUCIONAL', 40, lastY + 45);
  doc.setTextColor(150);
  doc.text('Cumplimiento Ley N° 29733 — identidad de reportantes no incluida', 555, lastY + 45, {
    align: 'right',
  });

  return doc;
}

// ── PDF — Detalle por incidente ───────────────────────────────────────────────
async function buildDetailPdf(
  incidents: PublicIncidentDTO[],
  filters: ExportFilters,
): Promise<jsPDF> {
  const doc = new jsPDF({ unit: 'pt', format: 'a4', orientation: 'landscape' });

  // Logo en esquina superior izquierda
  const logo = await loadLogoForPdf();
  let titleStartX = 40;
  if (logo) {
    const logoHeight = 24;
    const logoWidth  = (logo.width / logo.height) * logoHeight;
    doc.addImage(logo.dataUrl, 'PNG', 40, 32, logoWidth, logoHeight);
    titleStartX = 40 + logoWidth + 16;
  }

  doc.setFontSize(14);
  doc.setTextColor(13, 27, 42);
  doc.setFont('helvetica', 'bold');
  doc.text('Detalle de incidentes', titleStartX, 48);

  doc.setFontSize(9);
  doc.setTextColor(120);
  doc.setFont('helvetica', 'normal');
  doc.text(
    `Período: ${filters.from.toLocaleDateString('es-PE')} — ${filters.to.toLocaleDateString('es-PE')} · ${incidents.length} registros`,
    titleStartX,
    62,
  );

  autoTable(doc, {
    startY: 90,
    head:   [['Fecha', 'Tipo', 'Severidad', 'Estado', 'Distrito', 'Reportes', 'Confirman', 'Feedback']],
    body:   incidents.map((i) => [
      new Date(i.createdAt).toLocaleString('es-PE', { dateStyle: 'short', timeStyle: 'short' }),
      incidentTypeLabel[i.type],
      severityLabel[i.severity],
      statusLabel[i.status],
      i.district,
      i.reportCount,
      i.confirmCount,
      i.feedback ?? '—',
    ]),
    styles:    { fontSize: 8, cellPadding: 4 },
    headStyles: { fillColor: [27, 58, 107], textColor: 255 },
    alternateRowStyles: { fillColor: [248, 250, 252] },
    margin: { left: 40, right: 40 },
  });

  return doc;
}

// ── XLSX — Hoja única con todos los incidentes ───────────────────────────────
function buildXlsx(incidents: PublicIncidentDTO[], reportType: ReportType): XLSX.WorkBook {
  const wb = XLSX.utils.book_new();

  const rows = incidents.map((i) => ({
    Fecha:         new Date(i.createdAt).toLocaleString('es-PE'),
    Tipo:          incidentTypeLabel[i.type],
    Severidad:     severityLabel[i.severity],
    Estado:        statusLabel[i.status],
    Distrito:      i.district,
    Latitud:       i.lat,
    Longitud:      i.lng,
    Reportes:      i.reportCount,
    Confirman:     i.confirmCount,
    Desestiman:    i.denyCount,
    'Unidad asignada': i.unitAssigned ?? '',
    Feedback:      i.feedback ?? '',
  }));

  const ws = XLSX.utils.json_to_sheet(rows);
  XLSX.utils.book_append_sheet(wb, ws, 'Incidentes');

  // Si es Resumen Ejecutivo, agregar segunda hoja con KPIs
  if (reportType === 'executive') {
    const summary = [
      { Métrica: 'Total de incidentes', Valor: incidents.length },
      { Métrica: 'Críticos',            Valor: incidents.filter((i) => i.severity === 'CRITICAL').length },
      { Métrica: 'Moderados',           Valor: incidents.filter((i) => i.severity === 'MODERATE').length },
      { Métrica: 'Bajos',               Valor: incidents.filter((i) => i.severity === 'LOW').length },
      { Métrica: 'Activos',             Valor: incidents.filter((i) => i.status === 'ACTIVE').length },
      { Métrica: 'En atención',         Valor: incidents.filter((i) => i.status === 'IN_ATTENTION').length },
      { Métrica: 'Cerrados',            Valor: incidents.filter((i) => i.status === 'CLOSED').length },
      { Métrica: 'Distritos afectados', Valor: new Set(incidents.map((i) => i.district)).size },
    ];
    const wsSummary = XLSX.utils.json_to_sheet(summary);
    XLSX.utils.book_append_sheet(wb, wsSummary, 'Resumen');
  }

  return wb;
}

// ── API pública ───────────────────────────────────────────────────────────────
export async function generateExport(
  incidents: PublicIncidentDTO[],
  filters:   ExportFilters,
  format:    ReportFormat,
  type:      ReportType,
): Promise<{ filename: string; sizeKb: number }> {
  const ts = new Date().toISOString().slice(0, 10);
  const typeLabel = type === 'executive' ? 'Resumen' : type === 'detail' ? 'Detalle' : 'Formularios';

  if (format === 'pdf') {
    const doc = type === 'detail'
      ? await buildDetailPdf(incidents, filters)
      : await buildExecutivePdf(incidents, filters);
    const filename = `AlertaYa_${typeLabel}_${ts}.pdf`;
    const blob = doc.output('blob');
    triggerDownload(blob, filename);
    return { filename, sizeKb: Math.round(blob.size / 1024) };
  }

  const wb = buildXlsx(incidents, type);
  const filename = `AlertaYa_${typeLabel}_${ts}.xlsx`;
  const wbArray = XLSX.write(wb, { type: 'array', bookType: 'xlsx' }) as ArrayBuffer;
  const blob = new Blob([wbArray], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
  triggerDownload(blob, filename);
  return { filename, sizeKb: Math.round(blob.size / 1024) };
}

function triggerDownload(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ── Recent exports (localStorage) ─────────────────────────────────────────────
export function getRecentExports(): RecentExport[] {
  try {
    const raw = localStorage.getItem(RECENT_KEY);
    if (!raw) return [];
    return JSON.parse(raw) as RecentExport[];
  } catch {
    return [];
  }
}

export function saveRecentExport(record: RecentExport): RecentExport[] {
  const all = [record, ...getRecentExports()].slice(0, 5);
  localStorage.setItem(RECENT_KEY, JSON.stringify(all));
  return all;
}
