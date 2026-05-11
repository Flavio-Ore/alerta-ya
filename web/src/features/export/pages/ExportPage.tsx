import { Calendar, Activity, FileText, Download, CheckCircle, FileSpreadsheet } from 'lucide-react';

export default function ExportPage() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 h-full bg-[#0B111B] gap-1 p-1">
      {/* 1. CONFIGURACIÓN */}
      <div className="bg-[#0B111B] p-12 space-y-10 border-r border-slate-800">
        <div>
          <h1 className="text-2xl font-black text-white uppercase tracking-tighter mb-2">Exportar Reportes</h1>
          <p className="text-xs text-slate-500 uppercase font-bold tracking-widest">Configuración de salida táctica</p>
        </div>

        <div className="space-y-4">
          <label className="text-[10px] font-black text-slate-600 uppercase tracking-[0.2em]">Tipo de Reporte</label>
          <div className="grid grid-cols-2 gap-4">
            <button className="bg-[#111827] border-2 border-orange-500 p-6 flex flex-col gap-3 group relative overflow-hidden">
              <CheckCircle size={20} className="text-orange-500 absolute top-2 right-2" />
              <FileText className="text-orange-500" size={32} />
              <span className="text-sm font-bold text-white uppercase text-left leading-tight">Resumen Ejecutivo</span>
            </button>
            <button className="bg-[#111827] border-2 border-slate-800 p-6 flex flex-col gap-3 group hover:border-slate-700 transition-all">
              <Activity className="text-slate-500" size={32} />
              <span className="text-sm font-bold text-slate-400 uppercase text-left leading-tight">Análisis Predictivo</span>
            </button>
          </div>
        </div>

        <div className="space-y-4">
          <label className="text-[10px] font-black text-slate-600 uppercase tracking-[0.2em]">Selector de Período</label>
          <div className="flex gap-2 p-1 bg-[#111827] rounded-lg">
             {['ESTA SEMANA', 'ESTE MES', 'ULT. TRIMESTRE'].map((t, i) => (
               <button key={t} className={`flex-1 py-3 text-[9px] font-black uppercase rounded ${i === 1 ? 'bg-blue-600 text-white' : 'text-slate-500 hover:text-white'}`}>{t}</button>
             ))}
          </div>
          <div className="grid grid-cols-2 gap-4 mt-2">
             <div className="relative">
               <Calendar size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
               <input type="date" className="w-full bg-[#111827] border border-slate-800 p-3 pl-10 text-[10px] text-white outline-none focus:border-blue-500" />
             </div>
             <div className="relative">
               <Calendar size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
               <input type="date" className="w-full bg-[#111827] border border-slate-800 p-3 pl-10 text-[10px] text-white outline-none focus:border-blue-500" />
             </div>
          </div>
        </div>

        <div className="space-y-4">
          <label className="text-[10px] font-black text-slate-600 uppercase tracking-[0.2em]">Formato de Exportación</label>
          <div className="grid grid-cols-2 gap-4">
             <div className="bg-[#111827] p-4 border border-blue-500 flex items-center gap-3">
               <div className="h-10 w-10 bg-blue-500/10 flex items-center justify-center rounded-lg">
                  <span className="text-xs font-black text-blue-500 italic">PDF</span>
               </div>
               <div>
                  <p className="text-[10px] font-bold text-white uppercase">Para MININTER</p>
                  <p className="text-[8px] text-slate-500 uppercase tracking-widest font-bold">Oficial & Foliado</p>
               </div>
             </div>
             <div className="bg-[#111827] p-4 border border-slate-800 opacity-50 flex items-center gap-3 grayscale">
               <div className="h-10 w-10 bg-green-500/10 flex items-center justify-center rounded-lg">
                  <FileSpreadsheet size={18} className="text-green-500" />
               </div>
               <div>
                  <p className="text-[10px] font-bold text-slate-400 uppercase">Excel</p>
                  <p className="text-[8px] text-slate-600 uppercase tracking-widest font-bold">Data Cruda</p>
               </div>
             </div>
          </div>
        </div>

        <button className="w-full bg-blue-600 hover:bg-blue-700 text-white py-5 rounded-none font-black uppercase tracking-[0.2em] flex items-center justify-center gap-3 transition-all">
          <Download size={20} /> Generar Reporte
        </button>
      </div>

      {/* 2. VISUALIZACIÓN E HISTORIAL */}
      <div className="bg-[#05080d] p-12 overflow-y-auto">
        <div className="flex flex-col items-center mb-12">
          <p className="text-[10px] font-black text-slate-500 uppercase mb-4 tracking-widest italic">VISTA PREVIA DE DOCUMENTO</p>
          <div className="bg-white w-[420px] aspect-[1/1.414] scale-90 origin-top shadow-[0_40px_100px_rgba(0,0,0,0.5)] p-12 text-black flex flex-col">
             <div className="flex justify-between items-start border-b-2 border-black pb-4 mb-8">
               <div className="flex items-center gap-2">
                 <div className="h-8 w-8 bg-black flex items-center justify-center text-white text-[10px] font-black">AY</div>
                 <span className="text-[10px] font-black tracking-tighter">ALERTA YA</span>
               </div>
               <span className="text-[10px] font-bold tracking-widest uppercase opacity-40 italic">REPORTE ESTADÍSTICO</span>
             </div>
             
             <h2 className="text-2xl font-black uppercase tracking-tight mb-2">REPORTE MENSUAL</h2>
             <p className="text-[8px] font-bold text-slate-400 uppercase tracking-widest mb-8">ZONA METROPOLITANA LIMA • OCTUBRE 2023</p>
             
             <div className="grid grid-cols-2 gap-4 mb-8">
               <div className="bg-slate-50 p-4 border border-slate-100">
                  <p className="text-[6px] font-black uppercase opacity-50 mb-1">Total Incidentes</p>
                  <p className="text-xl font-black text-green-600">247</p>
               </div>
               <div className="bg-slate-50 p-4 border border-slate-100">
                  <p className="text-[6px] font-black uppercase opacity-50 mb-1">Riesgo Promedio</p>
                  <p className="text-xl font-black text-blue-600">81%</p>
               </div>
             </div>

             <div className="flex-1 border-2 border-dashed border-slate-100 rounded flex items-center justify-center">
                <span className="text-[8px] font-black text-slate-200 uppercase tracking-[0.4em] rotate-12">SECCIÓN DE MAPAS DE CALOR</span>
             </div>
          </div>
        </div>

        <div>
           <h3 className="text-[10px] font-black text-slate-500 uppercase mb-4 tracking-widest">Últimas Exportaciones</h3>
           <ul className="space-y-2">
             {[
               { name: 'Resumen_Ejecutivo_Oct23.pdf', date: 'Hace 2h', size: '1.2 MB' },
               { name: 'Data_Incidencias_Full.csv', date: 'Ayer', size: '24 MB' },
             ].map((file, i) => (
               <li key={i} className="bg-[#111827] p-4 border border-slate-800 flex justify-between items-center group cursor-pointer hover:border-slate-600 transition-all">
                 <div className="flex items-center gap-3">
                   <div className="h-8 w-8 bg-slate-800 rounded flex items-center justify-center text-slate-500 group-hover:text-white group-hover:bg-blue-600 transition-all">
                     <FileText size={16} />
                   </div>
                   <div>
                     <p className="text-xs font-bold text-white uppercase">{file.name}</p>
                     <p className="text-[8px] text-slate-500 uppercase font-black">{file.date} • {file.size}</p>
                   </div>
                 </div>
                 <Download size={16} className="text-slate-600 group-hover:text-blue-500" />
               </li>
             ))}
           </ul>
        </div>
      </div>
    </div>
  );
}