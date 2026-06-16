import { AlertTriangle, X } from "lucide-react";
import type { AdminUserDTO } from "../../../core/api/types";

interface Props {
  user: AdminUserDTO;
  onConfirm: () => void;
  onClose: () => void;
  isPending: boolean;
}

export function UserDeleteDialog({
  user,
  onConfirm,
  onClose,
  isPending,
}: Props) {
  const isDisabled = user.disabled;

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="bg-stitch-surface-container-low rounded-xl border border-stitch-surface-container-high w-full max-w-sm mx-4 overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-stitch-surface-container-high">
          <h2 className="text-sm font-bold text-white uppercase tracking-wider">
            {isDisabled ? "Rehabilitar autoridad" : "Deshabilitar autoridad"}
          </h2>
          <button
            onClick={onClose}
            className="text-stitch-on-surface-variant hover:text-white transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        <div className="p-6 space-y-4">
          <div className="flex items-center gap-3 p-3 bg-stitch-tertiary/10 border border-stitch-tertiary/30 rounded-lg">
            <AlertTriangle
              size={18}
              className="text-stitch-tertiary shrink-0"
            />
            <p className="text-xs text-stitch-on-surface-variant">
              {isDisabled
                ? `¿Rehabilitar a ${user.displayName ?? user.email}? Podrá iniciar sesión nuevamente.`
                : `¿Deshabilitar a ${user.displayName ?? user.email}? No podrá iniciar sesión hasta que sea rehabilitado.`}
            </p>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 bg-stitch-surface border border-stitch-surface-container-high text-stitch-on-surface-variant py-2.5 text-xs font-bold uppercase tracking-widest hover:bg-stitch-surface-container-high transition-all"
            >
              Cancelar
            </button>
            <button
              type="button"
              onClick={onConfirm}
              disabled={isPending}
              className={`flex-1 py-2.5 text-xs font-bold uppercase tracking-widest disabled:opacity-50 disabled:cursor-not-allowed transition-all ${
                isDisabled
                  ? "bg-green-600 text-white hover:bg-green-500"
                  : "bg-stitch-error text-white hover:bg-stitch-error/90"
              }`}
            >
              {isPending
                ? "Procesando…"
                : isDisabled
                  ? "Rehabilitar"
                  : "Deshabilitar"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
