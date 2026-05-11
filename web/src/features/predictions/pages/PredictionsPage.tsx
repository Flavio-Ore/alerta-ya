import { Brain, Sparkles, TrendingUp, Shield, Activity } from 'lucide-react';

export default function PredictionsPage() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-4 h-full bg-[#0B111B] gap-1 p-1">
      {/* SIDEBAR IA */}
      <aside className="bg-[#0f172a] p-8 border-r border-slate-800 flex flex-col">
        <div className="flex items-center gap-3 mb-8">
          <div className="h-10 w-10 bg-purple-600/20 rounded-xl flex items-center justify-center">
            <Brain className="text-purple-400" size={24} />
          </div>
          <div>
            <h2 className="text-sm font-black text-white uppercase tracking-tighter">Predicciones IA</h2>
            <p className="text-[10px] text-slate-500 font-bold uppercase">Análisis Táctico</p>
          </div>
        </div>

        <div className="space-y-6 flex-1">
          <div className="bg-purple-900/10 border border-purple-500/20 p-4 rounded-xl">
             <div className="flex justify-between items-center mb-2">
               <span className="text-[10px] font-black text-purple-400 uppercase">Modelo Activo</span>
               <span className="bg-purple-500 text-white text-[8px] font-bold px-1.5 py-0.5 rounded">V2.4</span>
             </div>
             <p className="text-xs font-bold text-white mb-1">Random Forest Classifier</p>
             <p className="text-[10px] text-slate-400 leading-tight italic">Entrenado con datos históricos del MININTER (2020-2026).</p>
             <div className="mt-4 flex items-center gap-2">
                <span className="text-xl font-black text-white">81%</span>
                <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Precisión</span>
             </div>
          </div>

          <nav className="space-y-2">
            {['Análisis Táctico', 'Historial IA', 'Configuración Modelo'].map((nav, i) => (
              <button key={nav} className={`w-full text-left px-4 py-3 text-xs font-bold uppercase tracking-widest rounded-lg transition-all ${i === 0 ? 'bg-purple-600/20 text-purple-400 border border-purple-500/30 shadow-[0_0_15px_rgba(147,51,234,0.1)]' : 'text-slate-500 hover:bg-slate-800/50'}`}>
                {nav}
              </button>
            ))}
          </nav>
        </div>

        <button className="bg-red-600/10 border border-red-500/20 p-4 rounded-xl text-left hover:bg-red-600/20 transition-all group">
          <Shield className="text-red-500 mb-2 group-hover:animate-pulse" size={20} />
          <p className="text-xs font-black text-white uppercase mb-1">Reforzar Cercado Lima</p>
          <p className="text-[10px] text-red-200/50 leading-tight">Se recomienda desplegar 4 patrullas adicionales en el sector 4.</p>
        </button>
      </aside>

      {/* MAPA IA CENTRAL */}
      <div className="lg:col-span-2 relative bg-slate-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://snazzy-maps-cdn.azureedge.net/assets/1243-retro.png?v=20170616052825')] opacity-20 grayscale scale-110" />
        {/* Heatmap Layer */}
        <div className="absolute top-[40%] left-[30%] w-[300px] h-[300px] bg-red-600/30 blur-[80px] rounded-full animate-pulse" />
        <div className="absolute top-[20%] left-[60%] w-[200px] h-[200px] bg-purple-600/20 blur-[60px] rounded-full" />
        
        {/* Overlay Blur Informativo */}
        <div className="absolute top-10 left-10 p-6 bg-[#0B111B]/40 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl">
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-1">Distrito Analizado</p>
          <h3 className="text-2xl font-black text-white tracking-tighter mb-4">Cercado de Lima</h3>
          
          <div className="grid grid-cols-2 gap-6">
            <div>
              <p className="text-[10px] font-bold text-slate-500 uppercase mb-1">Riesgo IA</p>
              <div className="flex items-center gap-2">
                <span className="text-3xl font-black text-red-500 drop-shadow-[0_0_10px_rgba(239,68,68,0.5)]">88%</span>
                <TrendingUp className="text-red-500" size={20} />
              </div>
            </div>
            <div>
              <p className="text-[10px] font-bold text-slate-500 uppercase mb-1">Ventana Crítica</p>
              <p className="text-xl font-bold text-white">15:00 - 17:00</p>
            </div>
          </div>
        </div>

        {/* Leyenda Escala */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 w-80 p-4 bg-[#0B111B]/80 border border-slate-700 backdrop-blur">
          <div className="flex justify-between text-[8px] font-black text-slate-500 uppercase mb-2 tracking-widest">
            <span>Bajo Riesgo</span>
            <span>Riesgo Crítico</span>
          </div>
          <div className="h-1.5 w-full bg-gradient-to-r from-green-500 via-yellow-500 to-red-500 rounded-full" />
        </div>
      </div>

      {/* WIDGETS DE DATOS IA (DERECHA) */}
      <aside className="bg-[#151C27] border-l border-slate-800 p-8 flex flex-col gap-8">
        <div className="space-y-4">
          <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Selector Temporal</h3>
          <div className="grid grid-cols-3 gap-2">
            {['1h', '6h', '24h'].map((t, i) => (
              <button key={t} className={`py-2 text-[10px] font-black uppercase rounded-lg border ${i === 0 ? 'bg-blue-600 border-blue-500 text-white' : 'border-slate-800 text-slate-500'}`}>{t}</button>
            ))}
          </div>
        </div>

        <div className="space-y-4">
           <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Ranking de Riesgo</h3>
           <div className="space-y-5">
             {[
               { name: 'Cercado Lima', val: 88, color: 'bg-red-500' },
               { name: 'La Victoria', val: 74, color: 'bg-orange-500' },
               { name: 'S.J.L', val: 62, color: 'bg-yellow-500' },
               { name: 'Callao', val: 45, color: 'bg-blue-500' },
             ].map(r => (
               <div key={r.name} className="space-y-1.5">
                 <div className="flex justify-between text-[10px] font-bold">
                   <span className="text-white uppercase">{r.name}</span>
                   <span className="text-slate-500">{r.val}%</span>
                 </div>
                 <div className="h-1 w-full bg-slate-800 rounded-full overflow-hidden">
                   <div className={`h-full ${r.color} transition-all duration-1000`} style={{ width: `${r.val}%` }} />
                 </div>
               </div>
             ))}
           </div>
        </div>

        <div className="space-y-4">
          <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Patrones Detectados</h3>
          <div className="space-y-3">
             <div className="bg-[#0B111B] p-4 border border-slate-800 space-y-2">
                <div className="flex items-center gap-2">
                  <Activity size={14} className="text-purple-400" />
                  <span className="text-[10px] font-black text-white uppercase">Uso de Armas</span>
                </div>
                <p className="text-xs text-slate-400">El <span className="text-white font-bold">68%</span> de incidentes probables involucran arma de fuego.</p>
             </div>
             <div className="bg-[#0B111B] p-4 border border-slate-800 space-y-2">
                <div className="flex items-center gap-2">
                  <Sparkles size={14} className="text-purple-400" />
                  <span className="text-[10px] font-black text-white uppercase">Modus Operandi</span>
                </div>
                <p className="text-xs text-slate-400">Alta probabilidad de escape vía <span className="text-white font-bold">Vehículos Menores</span> (Motocicletas).</p>
             </div>
          </div>
        </div>
      </aside>
    </div>
  );
}