import { Filter, Search, FileDown } from 'lucide-react';
import { useNavigate } from '@tanstack/react-router';

// Tipado básico para mejor control
interface Incident {
  id: string;
  type: string;
  dist: string;
  time: string;
  severity: 'CRÍTICO' | 'MODERADO' | 'BAJO';
  status: 'ACTIVO' | 'EN ATENCIÓN' | 'RESUELTO';
  reports: number;
}

export default function IncidentsListPage() {
  const navigate = useNavigate();

  const incidentsList: Incident[] = [
    { id: 'AL-128', type: 'Robo a mano armada', dist: 'San Isidro', time: '14:22', severity: 'CRÍTICO', status: 'ACTIVO', reports: 41 },
    { id: 'AL-129', type: 'Incendio estructural', dist: 'Centro Lima', time: '14:15', severity: 'CRÍTICO', status: 'ACTIVO', reports: 24 },
    { id: 'AL-130', type: 'Accidente de tránsito', dist: 'Miraflores', time: '14:05', severity: 'MODERADO', status: 'EN ATENCIÓN', reports: 8 },
  ];

  // Helper para colores de severidad
  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'CRÍTICO': return 'text-red-500';
      case 'MODERADO': return 'text-orange-500';
      default: return 'text-yellow-500';
    }
  };

  return (
    <div className="p-8 bg-[#0B111B] min-h-screen text-slate-200">
      {/* 1. PANEL DE CONTROL */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white uppercase tracking-tighter">Gestión de Incidentes</h1>
          <div className="flex gap-4 mt-2">
            <p className="text-xs text-slate-500 font-bold">
              <span className="text-white">47</span> INCIDENTES HOY
            </p>
            <p className="text-xs text-slate-500 font-bold">
              <span className="text-orange-500">14</span> ACTIVOS
            </p>
          </div>
        </div>
        
        <div className="flex flex-wrap gap-3 w-full md:w-auto">
          <div className="relative flex-grow md:flex-grow-0">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={16} />
            <input 
              type="text" 
              placeholder="Buscar incidente..." 
              className="bg-[#151C27] border border-slate-800 p-2 pl-10 text-xs w-full md:w-64 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all text-white" 
            />
          </div>
          <button className="flex items-center gap-2 bg-[#151C27] border border-slate-800 px-4 py-2 text-xs font-bold uppercase hover:bg-slate-800 transition-colors">
            <Filter size={14} /> Filtros
          </button>
          <button className="flex items-center gap-2 bg-blue-600 px-4 py-2 text-xs font-bold uppercase text-white hover:bg-blue-700 transition-colors">
            <FileDown size={14} /> Exportar
          </button>
        </div>
      </div>

      {/* 2. TABLA DE GESTIÓN */}
      <div className="bg-[#151C27] border border-slate-800 rounded-sm overflow-x-auto">
        <table className="w-full text-left text-xs min-w-[800px]">
          <thead>
            <tr className="bg-[#0B111B] text-slate-500 font-bold uppercase tracking-widest border-b border-slate-800">
              <th className="p-4">ID / Severidad</th>
              <th className="p-4">Tipo de Incidente</th>
              <th className="p-4">Ubicación y Hora</th>
              <th className="p-4">Estado</th>
              <th className="p-4 text-center">Reportes</th>
              <th className="p-4 text-right">Acción</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/50">
            {incidentsList.map((inc) => (
              <tr key={inc.id} className="hover:bg-white/5 transition-colors group">
                <td className="p-4">
                  <div className="flex flex-col gap-1">
                    <span className="font-mono text-slate-400">{inc.id}</span>
                    <span className={`text-[10px] font-black uppercase ${getSeverityColor(inc.severity)}`}>
                      {inc.severity}
                    </span>
                  </div>
                </td>
                <td className="p-4 font-bold text-white text-sm">{inc.type}</td>
                <td className="p-4">
                  <div className="flex flex-col">
                    <span className="text-slate-300 font-medium">{inc.dist}</span>
                    <span className="text-slate-500 font-mono text-[10px]">{inc.time} HRS</span>
                  </div>
                </td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-sm font-black text-[9px] border ${
                    inc.status === 'ACTIVO' 
                      ? 'bg-red-500/10 text-red-500 border-red-500/30' 
                      : 'bg-blue-500/10 text-blue-500 border-blue-500/30'
                  }`}>
                    {inc.status}
                  </span>
                </td>
                <td className="p-4 text-center">
                  <div className="inline-flex items-center justify-center h-8 w-8 rounded-full bg-slate-800 text-white font-bold ring-2 ring-slate-700 group-hover:ring-blue-500 transition-all">
                    {inc.reports}
                  </div>
                </td>
                <td className="p-4 text-right">
                  <button 
                    onClick={() => navigate({ to: '/incidents/$incidentId', params: { incidentId: inc.id } })}
                    className="bg-slate-800 hover:bg-blue-600 text-white text-[10px] font-bold uppercase px-4 py-2 transition-all rounded-sm"
                  >
                    Ver Detalle
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 3. PIE DE PÁGINA */}
      <div className="mt-8 flex flex-col md:flex-row justify-between items-center gap-4 border-t border-slate-800 pt-6">
        <p className="text-[10px] text-slate-500 italic max-w-md uppercase tracking-tighter leading-relaxed">
          Los datos mostrados no incluyen la identidad de los reportantes. 
          Cumplimiento Ley N° 29733 (Protección de Datos Personales, Perú).
        </p>
        <div className="flex gap-2">
          {[1, 2, 3, 4].map(p => (
            <button 
              key={p} 
              className={`h-8 w-8 text-xs font-bold border transition-colors ${
                p === 1 
                  ? 'bg-blue-600 border-blue-600 text-white' 
                  : 'bg-transparent border-slate-800 text-slate-500 hover:border-slate-600'
              }`}
            >
              {p}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}