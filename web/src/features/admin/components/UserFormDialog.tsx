import { X } from "lucide-react";
import { useState } from "react";
import type {
  AdminRole,
  AdminUserDTO,
  CreateAdminUserInput,
  UpdateAdminUserInput,
} from "../../../core/api/types";

interface Props {
  mode: "create" | "edit";
  user?: AdminUserDTO;
  onSave: (input: CreateAdminUserInput | UpdateAdminUserInput) => void;
  onClose: () => void;
  isPending: boolean;
}

export function UserFormDialog({
  mode,
  user,
  onSave,
  onClose,
  isPending,
}: Props) {
  const [email, setEmail] = useState(user?.email ?? "");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState(user?.displayName ?? "");
  const [role, setRole] = useState<AdminRole>(user?.role ?? "AUTHORITY");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (mode === "create") {
      onSave({ email, password, displayName, role } as CreateAdminUserInput);
    } else {
      const input: UpdateAdminUserInput = {};
      if (displayName !== user?.displayName) input.displayName = displayName;
      if (role !== user?.role) input.role = role;
      onSave(input);
    }
  }

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="bg-stitch-surface-container-low rounded-xl border border-stitch-surface-container-high w-full max-w-md mx-4 overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-stitch-surface-container-high">
          <h2 className="text-sm font-bold text-white uppercase tracking-wider">
            {mode === "create" ? "Nueva autoridad" : "Editar autoridad"}
          </h2>
          <button
            onClick={onClose}
            className="text-stitch-on-surface-variant hover:text-white transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold uppercase tracking-widest text-stitch-on-surface-variant font-label">
              Correo electrónico
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={mode === "edit"}
              className="w-full bg-stitch-surface border border-stitch-surface-container-high px-3 py-2.5 text-sm text-white outline-none focus:border-stitch-primary disabled:opacity-50 disabled:cursor-not-allowed"
              placeholder="autoridad@ejemplo.pe"
            />
          </div>

          {mode === "create" && (
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold uppercase tracking-widest text-stitch-on-surface-variant font-label">
                Contraseña temporal
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
                className="w-full bg-stitch-surface border border-stitch-surface-container-high px-3 py-2.5 text-sm text-white outline-none focus:border-stitch-primary"
                placeholder="Mín. 6 caracteres"
              />
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[10px] font-bold uppercase tracking-widest text-stitch-on-surface-variant font-label">
              Nombre completo
            </label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              required
              className="w-full bg-stitch-surface border border-stitch-surface-container-high px-3 py-2.5 text-sm text-white outline-none focus:border-stitch-primary"
              placeholder="John Doe"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[10px] font-bold uppercase tracking-widest text-stitch-on-surface-variant font-label">
              Rol
            </label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as AdminRole)}
              className="w-full bg-stitch-surface border border-stitch-surface-container-high px-3 py-2.5 text-sm text-white outline-none focus:border-stitch-primary"
            >
              <option value="AUTHORITY" className="bg-stitch-surface">
                Autoridad
              </option>
              <option value="ADMIN" className="bg-stitch-surface">
                Administrador
              </option>
            </select>
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 bg-stitch-surface border border-stitch-surface-container-high text-stitch-on-surface-variant py-2.5 text-xs font-bold uppercase tracking-widest hover:bg-stitch-surface-container-high transition-all"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isPending}
              className="flex-1 bg-stitch-primary text-white py-2.5 text-xs font-bold uppercase tracking-widest hover:bg-stitch-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              {isPending
                ? "Guardando…"
                : mode === "create"
                  ? "Crear"
                  : "Guardar"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
