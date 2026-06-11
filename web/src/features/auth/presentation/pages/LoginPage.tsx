import { useState, type FormEvent } from 'react';
import { useNavigate } from '@tanstack/react-router';
import { Lock, Mail, Eye, EyeOff, ChevronRight, ShieldAlert, AlertTriangle } from 'lucide-react';

import { useAuthStore } from '../stores/auth.store';
import { firebaseAvailable, firebaseConfigMissing } from '../../../../core/firebase/client';

/**
 * Login del panel de autoridades.
 *
 * TODO(HU008 H8-2): el docs pide "Auth Firebase con 2FA TOTP".
 * Firebase Auth soporta MFA TOTP a partir de v9+ pero requiere:
 *   1. Habilitar MFA en la consola Firebase del proyecto
 *   2. Plan Identity Platform (no el plan free)
 *   3. multiFactor.enroll(...) durante el setup del usuario autoridad
 *   4. Resolver `MultiFactorError` con `getMultiFactorResolver()` durante login
 * Pendiente hasta que se confirme que el proyecto Firebase tiene Identity Platform.
 */

export default function LoginPage() {
  const navigate = useNavigate();
  const signIn = useAuthStore((s) => s.signIn);
  const isAuthenticating = useAuthStore((s) => s.isAuthenticating);
  const error = useAuthStore((s) => s.error);
  const clearError = useAuthStore((s) => s.clearError);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    clearError();
    try {
      await signIn(email, password);
      await navigate({ to: '/dashboard' });
    } catch {
      // El error ya quedó en el store
    }
  }

  return (
    <div className="flex h-screen w-full bg-ay-dark font-sans text-ay-text-muted">
      {/* Lateral izquierdo — identidad */}
      <div className="hidden lg:flex w-1/2 bg-ay-bg-dark2 relative flex-col justify-between p-12 overflow-hidden border-r border-ay-border">
        <div className="relative z-10">
          <img
            src="/assets/logo/alertaya-logo-dark.svg"
            alt="AlertaYa"
            className="h-10"
          />
          <div className="mt-20">
            <h1 className="text-6xl font-bold text-white tracking-tight leading-tight">
              Panel de <br />
              <span className="text-ay-accent">Autoridades</span>
            </h1>
            <p className="mt-4 text-ay-text-secondary text-lg font-medium">
              Red Ciudadana de Seguridad · Lima, Perú
            </p>
          </div>
        </div>

        <div className="relative z-10 flex gap-6 text-[10px] font-bold tracking-[0.2em] text-ay-text-secondary uppercase">
          <span>PNP</span>
          <span>SERENAZGO</span>
          <span>MUNICIPALIDAD</span>
        </div>
      </div>

      {/* Derecha — formulario */}
      <div className="w-full lg:w-1/2 flex flex-col items-center justify-center p-8 relative">
        <form onSubmit={handleSubmit} className="w-full max-w-md space-y-8">
          <div className="space-y-2">
            <h2 className="text-3xl font-bold text-white">Iniciar Sesión</h2>
            <div className="flex items-center gap-2 text-xs font-bold text-ay-accent uppercase tracking-widest bg-ay-accent/10 p-2 border border-ay-accent/20 w-fit">
              <Lock size={12} /> Acceso restringido — solo personal autorizado
            </div>
          </div>

          {!firebaseAvailable && (
            <div className="flex items-start gap-3 text-xs text-ay-accent bg-ay-accent/10 border border-ay-accent/30 p-4">
              <AlertTriangle size={16} className="mt-0.5 shrink-0" />
              <div className="space-y-2">
                <p className="font-bold uppercase tracking-wide">Firebase no está configurado</p>
                <p>Faltan variables de entorno en <code className="font-mono">web/.env</code>:</p>
                <ul className="font-mono text-[11px] space-y-0.5">
                  {firebaseConfigMissing.map((v) => (
                    <li key={v}>· {v}</li>
                  ))}
                </ul>
                <p className="pt-1">
                  Copiá <code className="font-mono">web/.env.example</code> a <code className="font-mono">web/.env</code> y completá con las credenciales del proyecto Firebase, después reiniciá el dev server.
                </p>
              </div>
            </div>
          )}

          <div className="space-y-5">
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-ay-text-secondary" size={18} />
              <input
                type="email"
                required
                autoComplete="email"
                placeholder="supervisor@serenazgolima.gob.pe"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-ay-bg-dark border border-ay-border p-3 pl-10 outline-none focus:border-ay-primary transition-all text-sm text-white"
              />
            </div>

            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-ay-text-secondary" size={18} />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                autoComplete="current-password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-ay-bg-dark border border-ay-border p-3 pl-10 pr-10 outline-none focus:border-ay-primary transition-all text-sm text-white"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-ay-text-secondary hover:text-white"
                aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>

            {error && (
              <div className="flex items-start gap-2 text-xs text-ay-critical bg-ay-critical/10 border border-ay-critical/20 p-3">
                <ShieldAlert size={14} className="mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={isAuthenticating || !firebaseAvailable}
              className="w-full bg-ay-primary hover:bg-ay-primary/90 disabled:opacity-60 disabled:cursor-not-allowed text-white font-bold py-4 flex items-center justify-center gap-2 transition-all group"
            >
              {isAuthenticating ? 'Verificando…' : 'Acceder al panel'}
              {!isAuthenticating && (
                <ChevronRight size={18} className="group-hover:translate-x-1 transition-transform" />
              )}
            </button>

            <p className="text-center text-xs text-ay-text-secondary mt-6">
              ¿Problemas de acceso?{' '}
              <span className="text-ay-accent cursor-pointer hover:underline">
                Contactá a soporte técnico
              </span>
            </p>
          </div>
        </form>

        <div className="absolute bottom-8 right-8 flex items-center gap-2 text-[10px] font-bold tracking-widest text-ay-text-secondary uppercase">
          <span className="flex h-2 w-2 rounded-full bg-ay-low animate-pulse" />
          Servidor activo en línea
        </div>
      </div>
    </div>
  );
}
