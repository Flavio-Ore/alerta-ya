import { useState, useEffect } from 'react';
import { ShieldAlert, Lock, Mail, Eye, MapPin, ChevronRight } from 'lucide-react';

export default function LoginPage() {
  const [timer, setTimer] = useState(42);

  return (
    <div className="flex h-screen w-full bg-[#0B111B] font-sans text-slate-200">
      {/* 1. SECCIÓN LATERAL IZQUIERDA (IDENTIDAD) */}
      <div className="hidden lg:flex w-1/2 bg-[#05080d] relative flex-col justify-between p-12 overflow-hidden border-r border-slate-800/50">
        <div className="absolute inset-0 opacity-10 bg-[url('https://www.mapasnet.com/images/lima-vector.png')] bg-cover mix-blend-overlay" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="bg-orange-500 p-2 rounded-full ring-4 ring-white/10">
              <MapPin className="text-white" size={24} />
            </div>
            <span className="text-2xl font-black tracking-tighter text-white">ALERTA YA</span>
          </div>
          <div className="mt-20">
            <h1 className="text-6xl font-bold text-white tracking-tight leading-tight">
              Panel de <br /> <span className="text-blue-500">Autoridades</span>
            </h1>
            <p className="mt-4 text-slate-400 text-lg font-medium">
              Red Ciudadana de Seguridad • Lima, Perú
            </p>
          </div>
        </div>

        <div className="relative z-10 flex gap-6 text-[10px] font-bold tracking-[0.2em] text-slate-600 uppercase">
          <span>PML</span>
          <span>SERENAZGO</span>
          <span>MUNICIPALIDAD</span>
        </div>
      </div>

      {/* 2. SECCIÓN DERECHA (FORMULARIO) */}
      <div className="w-full lg:w-1/2 flex flex-col items-center justify-center p-8 relative">
        <div className="w-full max-w-md space-y-8">
          <div className="space-y-2">
            <h2 className="text-3xl font-bold text-white">Iniciar Sesión</h2>
            <div className="flex items-center gap-2 text-xs font-bold text-yellow-500 uppercase tracking-widest bg-yellow-500/10 p-2 border border-yellow-500/20 w-fit">
              <Lock size={12} /> ACCESO RESTRINGIDO — SOLO PERSONAL AUTORIZADO
            </div>
          </div>

          <div className="space-y-5">
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              <input type="email" placeholder="supervisor@serenazgolima.gob.pe" className="w-full bg-[#151C27] border border-slate-700 p-3 pl-10 outline-none focus:border-blue-500 transition-all text-sm" />
            </div>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              <input type="password" placeholder="••••••••" className="w-full bg-[#151C27] border border-slate-700 p-3 pl-10 pr-10 outline-none focus:border-blue-500 transition-all text-sm" />
              <Eye className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 cursor-pointer" size={18} />
            </div>

            <div className="space-y-3 pt-4">
              <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Código de verificación</label>
              <div className="flex justify-between gap-2">
                {[...Array(6)].map((_, i) => (
                  <input key={i} type="text" maxLength={1} className="w-12 h-14 bg-[#151C27] border border-slate-700 text-center text-xl font-bold text-blue-500 focus:border-blue-400 outline-none" />
                ))}
              </div>
              <p className="text-[11px] text-slate-500">El código fue enviado a tu teléfono registrado.</p>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400">Reenviar código · <span className="text-blue-500">00:{timer}</span></span>
              </div>
            </div>

            <button className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-4 flex items-center justify-center gap-2 transition-all group">
              ACCEDER AL PANEL <ChevronRight size={18} className="group-hover:translate-x-1 transition-transform" />
            </button>

            <p className="text-center text-xs text-slate-500 mt-6">
              ¿Problemas de acceso? <span className="text-blue-500 cursor-pointer hover:underline">Contacta a soporte técnico</span>
            </p>
          </div>
        </div>

        {/* ESTADO DEL SISTEMA */}
        <div className="absolute bottom-8 right-8 flex items-center gap-2 text-[10px] font-bold tracking-widest text-slate-500 uppercase">
          <span className="flex h-2 w-2 rounded-full bg-green-500 animate-pulse" />
          SERVIDOR ACTIVO EN LÍNEA
        </div>
      </div>
    </div>
  );
}