import { Map as MapIcon, Activity, Brain, BarChart3, Download, Bell, AlertCircle, ShieldCheck } from 'lucide-react';

export default function DashboardPage() {
  const stats = [
    { label: 'ACTIVOS', val: '14', color: 'text-orange-500' },
    { label: 'CRÍTICOS', val: '3', color: 'text-red-500' },
    { label: 'REPORTES HOY', val: '47', color: 'text-white' },
    { label: 'RESPUESTA PROM.', val: '6 min', target: '5 min', color: 'text-blue-400' },
  ];

  return (
    <div className="flex h-screen bg-[#0B111B] text-slate-300">
      {/* 1. BARRA LATERAL */}
      {/* <aside className="w-64 border-r border-slate-800 bg-[#0B111B] flex flex-col p-6">
        <div className="flex items-center gap-2 mb-10">
          <div className="h-8 w-8 bg-orange-500 rounded flex items-center justify-center font-bold text-white text-xs">AY</div>
          <span className="font-bold tracking-tighter text-white">ALERTA YA</span>
        </div>

        <nav className="flex-1 space-y-1">
          {[
            { icon: MapIcon, label: 'Mapa en Vivo', active: true },
            { icon: Bell, label: 'Incidentes' },
            { icon: Brain, label: 'Predicciones IA' },
            { icon: BarChart3, label: 'Estadísticas' },
            { icon: Download, label: 'Exportar' },
          ].map((item) => (
            <button key={item.label} className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all ${item.active ? 'bg-blue-600/10 text-blue-500 border-l-2 border-blue-500' : 'hover:bg-slate-800/50'}`}>
              <item.icon size={18} /> {item.label}
            </button>
          ))}
        </nav>

        <div className="pt-6 border-t border-slate-800">
          <div className="flex items-center gap-3">
            <div className="h-8 w-8 rounded-full bg-slate-700" />
            <div>
              <p className="text-xs font-bold text-white">Sup. García</p>
              <p className="text-[10px] text-slate-500 uppercase">Comisaría San Isidro</p>
            </div>
          </div>
        </div>
      </aside> */}

      <main className="flex-1 flex flex-col overflow-hidden">
        {/* 2. PANEL SUPERIOR */}
        <header className="h-20 border-b border-slate-800 bg-[#0B111B]/80 backdrop-blur flex items-center px-8 gap-12">
          {stats.map(s => (
            <div key={s.label} className="space-y-1">
              <p className="text-[10px] font-bold text-slate-500 tracking-widest">{s.label}</p>
              <div className="flex items-baseline gap-2">
                <span className={`text-2xl font-black ${s.color}`}>{s.val}</span>
                {s.target && <span className="text-[10px] text-slate-600">Goal: {s.target}</span>}
              </div>
            </div>
          ))}
        </header>

        {/* 3. ÁREA CENTRAL */}
        <div className="flex-1 flex overflow-hidden">
          <div className="flex-1 relative bg-slate-900 border-r border-slate-800">
             {/* Mockup Mapa Calor */}
            <div className="absolute inset-0 bg-[url('https://snazzy-maps-cdn.azureedge.net/assets/1243-retro.png?v=20170616052825')] opacity-20 grayscale" />
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[400px] h-[400px] bg-red-500/20 blur-[100px] rounded-full" />
            
            <div className="absolute bottom-6 left-6 bg-[#0B111B]/90 border border-slate-700 p-4 rounded-lg">
              <p className="text-[10px] font-bold text-slate-500 mb-3 uppercase tracking-tighter">Leyenda de Prioridad</p>
              <div className="space-y-2">
                <div className="flex items-center gap-3 text-[10px] font-bold"><span className="h-2 w-2 rounded-full bg-red-500" /> CRÍTICO</div>
                <div className="flex items-center gap-3 text-[10px] font-bold"><span className="h-2 w-2 rounded-full bg-orange-500" /> MODERADO</div>
                <div className="flex items-center gap-3 text-[10px] font-bold"><span className="h-2 w-2 rounded-full bg-green-500" /> INFORMATIVO</div>
              </div>
            </div>
          </div>

          {/* 4. COLUMNA DERECHA (INCIDENTES) */}
          <aside className="w-96 flex flex-col bg-[#0B111B]">
            <div className="p-4 border-b border-slate-800 flex justify-between items-center">
              <h3 className="text-xs font-bold uppercase tracking-widest text-slate-500">Incidentes Activos</h3>
              <Activity size={14} className="text-blue-500" />
            </div>
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              <div className="bg-[#151C27] border-l-4 border-red-500 p-4 space-y-2">
                <div className="flex justify-between items-start">
                  <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 font-bold uppercase">CRÍTICO</span>
                  <span className="text-[10px] text-slate-500">Hace 2 min</span>
                </div>
                <p className="text-sm font-bold text-white">Robo a Mano Armada</p>
                <p className="text-[11px] text-slate-400 italic">Av. Larco. Sujetos en moto lineal con arma de fuego.</p>
                <button className="w-full mt-2 bg-blue-600 hover:bg-blue-700 py-2 text-[10px] font-bold uppercase text-white transition-colors">Asignar Unidad</button>
              </div>
              
              <div className="bg-[#151C27] border-l-4 border-orange-500 p-4 space-y-2">
                 <div className="flex justify-between items-start">
                  <span className="text-[10px] bg-orange-500 text-white px-2 py-0.5 font-bold uppercase">ACTIVO</span>
                  <span className="text-[10px] text-slate-500">Hace 15 min</span>
                </div>
                <p className="text-sm font-bold text-white">Actividad Sospechosa</p>
                <p className="text-[11px] text-slate-400">Vehículo lunas polarizadas frente a banco.</p>
                <button className="w-full mt-2 border border-slate-700 hover:bg-slate-800 py-2 text-[10px] font-bold uppercase">Asignar Unidad</button>
              </div>
            </div>
          </aside>
        </div>
      </main>
    </div>
  );
}