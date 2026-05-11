import { Siren, Users, History, CheckCircle2, Navigation, Clock } from 'lucide-react';

export default function IncidentDetailPage() {
  return (
    <div className="p-8 space-y-6">
      {/* 1. CABECERA Y ESTADO CRÍTICO */}
      <div className="flex justify-between items-start bg-red-950/20 border border-red-500/30 p-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <span className="bg-red-500 text-white text-xs font-black px-3 py-1 uppercase animate-pulse">CRÍTICO</span>
            <h1 className="text-2xl font-bold text-white tracking-tighter uppercase">Av. Larco cdra 3, Miraflores</h1>
          </div>
          <p className="text-xs text-slate-500 flex items-center gap-2">
            <Clock size={14} /> Reportado hace 22 min • 14:12 PM
          </p>
        </div>
        <div className="text-right">
          <p className="text-[10px] font-bold text-red-500 uppercase tracking-[0.2em] mb-1">SLA - Tiempo Límite</p>
          <p className="text-3xl font-mono font-bold text-white">08:34</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 2. INTELIGENCIA DE DATOS (COLUMNA IZQUIERDA) */}
        <div className="lg:col-span-2 space-y-6">
          <div className="h-64 bg-slate-900 border border-slate-800 relative">
            <div className="absolute inset-0 bg-[url('https://snazzy-maps-cdn.azureedge.net/assets/1243-retro.png?v=20170616052825')] opacity-30 grayscale" />
            <div className="absolute top-1/2 left-1/2 h-8 w-8 bg-red-500/50 rounded-full animate-ping" />
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-4 w-4 bg-red-500 border-2 border-white rounded-full shadow-[0_0_20px_rgba(239,68,68,0.5)]" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-[#151C27] p-6 border border-slate-800 space-y-4">
              <h3 className="text-[10px] font-bold uppercase tracking-widest text-slate-500">Inteligencia Ciudadana</h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center border-b border-slate-800 pb-2">
                  <span className="text-xs text-slate-400 uppercase">Involucrados</span>
                  <span className="text-xs font-bold text-white">2-3 PERSONAS</span>
                </div>
                <div className="flex justify-between items-center border-b border-slate-800 pb-2">
                  <span className="text-xs text-slate-400 uppercase">Peligro</span>
                  <span className="text-xs font-bold text-red-500 uppercase flex items-center gap-1">
                    <Siren size={12} /> Arma de Fuego
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-slate-400 uppercase">Estado</span>
                  <span className="text-xs font-bold text-orange-500">TODAVÍA EN ZONA</span>
                </div>
              </div>
              <div className="bg-orange-500/10 border border-orange-500/20 p-3">
                 <p className="text-[10px] text-orange-200 font-bold leading-tight">ESCALAMIENTO AUTOMÁTICO: 3 usuarios coincidieron en descripción de armas.</p>
              </div>
            </div>

            <div className="bg-[#151C27] p-6 border border-slate-800 flex flex-col items-center justify-center text-center">
              <div className="h-20 w-20 rounded-full border-4 border-blue-600 flex items-center justify-center mb-3">
                <span className="text-2xl font-black text-white">86%</span>
              </div>
              <p className="text-xs font-bold uppercase tracking-tighter text-blue-400 mb-1">Validación Social</p>
              <p className="text-[10px] text-slate-500 uppercase">Ciudadanos cercanos confirman que el incidente sigue activo.</p>
            </div>
          </div>
        </div>

        {/* 3. GESTIÓN DE RESPUESTA (COLUMNA DERECHA) */}
        <div className="space-y-6">
          <div className="bg-[#151C27] border border-slate-800 p-6">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-6 flex items-center gap-2">
              <History size={14} /> Línea de Tiempo
            </h3>
            <div className="space-y-6 relative before:absolute before:left-2 before:top-0 before:h-full before:w-[1px] before:bg-slate-800">
              <div className="relative pl-8">
                <div className="absolute left-0 top-1 h-4 w-4 bg-blue-600 rounded-full" />
                <p className="text-[11px] text-slate-500 font-mono">14:12 PM</p>
                <p className="text-xs font-bold text-white">Reporte Inicial recibido</p>
              </div>
              <div className="relative pl-8">
                <div className="absolute left-0 top-1 h-4 w-4 bg-orange-500 rounded-full" />
                <p className="text-[11px] text-slate-500 font-mono">14:26 PM</p>
                <p className="text-xs font-bold text-white uppercase">Prioridad Escalada por IA</p>
              </div>
            </div>
          </div>

          <div className="bg-[#151C27] border border-slate-800 p-6 space-y-4">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-slate-500">Unidades Disponibles</h3>
            <div className="space-y-2">
              {['Patrullero 07', 'Patrullero 12', 'Serenazgo M-03'].map(u => (
                <div key={u} className="flex justify-between items-center bg-[#0B111B] p-3 border border-slate-800">
                  <div className="flex items-center gap-3">
                    <Navigation size={14} className="text-blue-500" />
                    <span className="text-xs font-bold text-white">{u}</span>
                  </div>
                  <button className="text-[10px] font-bold uppercase text-blue-400 hover:text-white transition-colors">Asignar</button>
                </div>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-2">
             <button className="bg-blue-600 text-white py-3 text-xs font-black uppercase tracking-widest shadow-[0_0_20px_rgba(37,99,235,0.3)] hover:scale-[1.02] transition-all">En Atención</button>
             <button className="bg-slate-800 text-slate-400 py-3 text-xs font-black uppercase tracking-widest hover:bg-slate-700 transition-all">Cerrar Incidente</button>
          </div>
        </div>
      </div>

      <div className="flex justify-end pt-4">
        <p className="text-[10px] font-bold text-slate-600 uppercase flex items-center gap-2">
          <CheckCircle2 size={12} /> Identidad del reportante cifrada (Solo accesible bajo orden judicial)
        </p>
      </div>
    </div>
  );
}