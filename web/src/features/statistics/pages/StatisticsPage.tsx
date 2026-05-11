import { ArrowUpRight, Target, AlertTriangle, Zap, Clock } from 'lucide-react';

export default function StatisticsPage() {
  return (
    <div className="p-8 space-y-8 bg-[#0B111B] min-h-screen">
      {/* 1. CABECERA */}
      <div className="flex justify-between items-end">
        <div>
          <p className="text-[10px] font-black text-blue-500 uppercase tracking-widest">Authority Oversight</p>
          <h1 className="text-3xl font-black text-white uppercase tracking-tighter">Estadísticas</h1>
        </div>
        <div className="flex gap-2">
          {['ESTA SEMANA', 'ESTE MES', 'ÚLTIMOS 3 MESES', 'PERSONALIZADO'].map((f, i) => (
            <button key={f} className={`px-4 py-2 text-[10px] font-bold uppercase tracking-widest border transition-all ${i === 1 ? 'bg-blue-600 border-blue-600 text-white' : 'border-slate-800 text-slate-500 hover:border-slate-700'}`}>{f}</button>
          ))}
        </div>
      </div>

      {/* 2. KPIs SUPERIORES */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        {[
          { label: 'Total Reportes', val: '247', trend: '+12%', icon: ArrowUpRight, color: 'text-green-500' },
          { label: 'Formulario Completo', val: '68%', status: 'online', color: 'text-green-400' },
          { label: 'Severidad Crítico', val: '34%', icon: AlertTriangle, color: 'text-red-500' },
          { label: 'Precisión IA', val: '81%', icon: Target, color: 'text-blue-500' },
          { label: 'Tiempo Respuesta', val: '4.2 min', icon: Zap, color: 'text-orange-500' },
        ].map(kpi => (
          <div key={kpi.label} className="bg-[#1F2937] p-5 rounded-xl border border-slate-800">
             <div className="flex justify-between items-start mb-2">
               <p className="text-[9px] font-black text-slate-500 uppercase tracking-widest">{kpi.label}</p>
               {kpi.icon && <kpi.icon size={14} className={kpi.color} />}
               {kpi.status && <div className="h-1.5 w-1.5 rounded-full bg-green-500 animate-pulse" />}
             </div>
             <div className="flex items-end gap-2">
               <span className="text-2xl font-black text-white leading-none">{kpi.val}</span>
               {kpi.trend && <span className="text-[9px] font-bold text-green-500 mb-1">{kpi.trend}</span>}
             </div>
          </div>
        ))}
      </div>

      {/* 3. GRÁFICOS MEDIOS */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#1F2937] p-8 rounded-xl border border-slate-800">
          <h3 className="text-xs font-black text-slate-500 uppercase tracking-[0.2em] mb-8">Reportes por Tipo de Incidente</h3>
          <div className="space-y-6">
             {[
               { name: 'ROBO / ASALTO', val: 75, color: 'bg-red-500' },
               { name: 'ACCIDENTE VIAL', val: 55, color: 'bg-orange-500' },
               { name: 'ACTIVIDAD SOSPECHOSA', val: 40, color: 'bg-blue-500' },
               { name: 'DISTURBIO PÚBLICO', val: 20, color: 'bg-slate-500' },
             ].map(item => (
               <div key={item.name} className="space-y-2">
                 <div className="flex justify-between text-[10px] font-bold uppercase tracking-widest">
                    <span className="text-white">{item.name}</span>
                    <span className="text-slate-500">{item.val} Casos</span>
                 </div>
                 <div className="h-2 w-full bg-slate-900 rounded-none">
                    <div className={`h-full ${item.color}`} style={{ width: `${item.val}%` }} />
                 </div>
               </div>
             ))}
          </div>
        </div>

        <div className="bg-[#1F2937] p-8 rounded-xl border border-slate-800">
          <h3 className="text-xs font-black text-slate-500 uppercase tracking-[0.2em] mb-8">Incidentes por Día y Hora</h3>
          <div className="grid grid-cols-[20px_repeat(16,1fr)] gap-1 h-40">
            <div className="flex flex-col justify-between text-[8px] font-black text-slate-600 h-full py-2">
              <span>LUN</span><span>MIE</span><span>DOM</span>
            </div>
            {[...Array(16)].map((_, i) => (
              <div key={i} className="flex flex-col gap-1 h-full">
                {[...Array(7)].map((_, j) => (
                  <div key={j} className={`flex-1 ${Math.random() > 0.8 ? 'bg-red-500' : Math.random() > 0.6 ? 'bg-orange-500' : 'bg-slate-800'}`} />
                ))}
              </div>
            ))}
          </div>
          <div className="flex justify-between text-[8px] font-black text-slate-600 mt-2 px-6 tracking-widest uppercase">
            <span>00h</span><span>04h</span><span>08h</span><span>12h</span><span>16h</span>
          </div>
        </div>
      </div>

      {/* 4. ANÁLISIS DE RESPUESTAS */}
      <div className="bg-[#1F2937] p-8 rounded-xl border border-slate-800">
        <h3 className="text-xs font-black text-slate-500 uppercase tracking-[0.2em] mb-8">Análisis de Respuestas – Formulario Dinámico</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
          {/* Donut Chart Mockup */}
          <div className="flex flex-col items-center">
             <div className="h-32 w-32 rounded-full border-[12px] border-slate-800 relative flex flex-col items-center justify-center">
                <div className="absolute inset-[-12px] border-[12px] border-t-red-500 border-r-orange-500 border-b-slate-500 border-l-red-500 rounded-full" />
                <span className="text-2xl font-black text-white">127</span>
                <span className="text-[8px] font-bold text-slate-500 uppercase">Casos</span>
             </div>
             <p className="text-[10px] font-bold text-slate-400 mt-4 uppercase tracking-widest mb-4">Tipo de Arma</p>
             <div className="flex gap-4 text-[8px] font-bold">
               <span className="flex items-center gap-1"><div className="h-1.5 w-1.5 bg-red-500" /> FUEGO (52%)</span>
               <span className="flex items-center gap-1"><div className="h-1.5 w-1.5 bg-orange-500" /> BLANCA (23%)</span>
             </div>
          </div>

          <div className="space-y-6">
             <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Huida del Agresor</p>
             {[
               { mode: 'A PIE', pct: 45 },
               { mode: 'VEHÍCULO', pct: 38 },
               { mode: 'MOTOCICLETA', pct: 17 },
             ].map(m => (
               <div key={m.mode} className="flex justify-between items-center border-b border-slate-800 pb-2">
                  <span className="text-xs font-bold text-white uppercase">{m.mode}</span>
                  <span className="text-xs font-black text-blue-500">{m.pct}%</span>
               </div>
             ))}
             <div className="bg-orange-500/10 p-3 border-l-2 border-orange-500">
                <p className="text-[9px] font-bold text-orange-200 leading-tight">ALTA RECURRENCIA: La Victoria concentra el 62% de huidas en vehículo.</p>
             </div>
          </div>

          <div className="flex flex-col items-center justify-center text-center">
             <Clock size={40} className="text-blue-500 mb-4" />
             <span className="text-4xl font-black text-white">67%</span>
             <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mt-2">Ventana de Intervención</p>
             <p className="text-xs text-blue-400 font-bold mt-1 tracking-tighter uppercase">Menos de 4.2 min en zona</p>
          </div>
        </div>
      </div>
    </div>
  );
}