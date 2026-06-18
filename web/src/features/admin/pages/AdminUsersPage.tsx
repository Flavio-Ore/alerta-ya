import { useMemo, useState, useCallback } from "react";
import { Plus, RotateCcw } from "lucide-react";

import {
  useAdminUsersList,
  useCreateAdminUser,
  useUpdateAdminUser,
  useDisableAdminUser,
  useEnableAdminUser,
} from "../infrastructure/admin.api";
import { UserFormDialog } from "../components/UserFormDialog";
import { UserDeleteDialog } from "../components/UserDeleteDialog";
import type {
  AdminUserDTO,
  AdminRole,
  CreateAdminUserInput,
  UpdateAdminUserInput,
} from "../../../core/api/types";

const PAGE_SIZE = 20;

export default function AdminUsersPage() {
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState<AdminRole | "ALL">("ALL");
  const [page, setPage] = useState(1);

  const [formOpen, setFormOpen] = useState<"create" | "edit" | null>(null);
  const [editingUser, setEditingUser] = useState<AdminUserDTO | null>(null);
  const [deletingUser, setDeletingUser] = useState<AdminUserDTO | null>(null);

  const query = useMemo(
    () => ({
      search: search || undefined,
      page,
      pageSize: PAGE_SIZE,
      role: roleFilter === "ALL" ? undefined : roleFilter,
    }),
    [search, page, roleFilter],
  );

  const { data, isLoading, isError, error } = useAdminUsersList(query);
  const createMutation = useCreateAdminUser();
  const updateMutation = useUpdateAdminUser();
  const disableMutation = useDisableAdminUser();
  const enableMutation = useEnableAdminUser();

  const totalPages = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;

  const handleCreate = useCallback(
    (input: CreateAdminUserInput) => {
      createMutation.mutate(input, { onSuccess: () => setFormOpen(null) });
    },
    [createMutation],
  );

  const handleUpdate = useCallback(
    (input: UpdateAdminUserInput) => {
      if (!editingUser) return;
      updateMutation.mutate(
        { uid: editingUser.uid, input },
        {
          onSuccess: () => {
            setFormOpen(null);
            setEditingUser(null);
          },
        },
      );
    },
    [updateMutation, editingUser],
  );

  const handleToggleDisable = useCallback(() => {
    if (!deletingUser) return;
    if (deletingUser.disabled) {
      enableMutation.mutate(deletingUser.uid, {
        onSuccess: () => setDeletingUser(null),
      });
    } else {
      disableMutation.mutate(deletingUser.uid, {
        onSuccess: () => setDeletingUser(null),
      });
    }
  }, [deletingUser, enableMutation, disableMutation]);

  const openEdit = useCallback((user: AdminUserDTO) => {
    setEditingUser(user);
    setFormOpen("edit");
  }, []);

  const searchValue = search;
  const setSearchValue = setSearch;
  const setPageValue = setPage;

  return (
    <div className="flex-1 flex flex-col overflow-hidden bg-stitch-surface">
      <header className="flex items-center justify-between px-10 py-8">
        <div className="flex flex-col gap-1">
          <h2 className="text-2xl font-bold text-white font-headline tracking-tight">
            Administrar Autoridades
          </h2>
          <p className="text-sm text-stitch-on-surface-variant font-medium">
            {data?.total ?? "—"} usuarios ·{" "}
            <span className="text-stitch-primary">
              {data?.items.filter((u) => !u.disabled).length ?? 0} activos
            </span>
          </p>
        </div>
        <button
          onClick={() => {
            setEditingUser(null);
            setFormOpen("create");
          }}
          className="flex items-center gap-2 px-5 py-2.5 bg-stitch-primary text-white rounded-lg hover:bg-stitch-primary/90 transition-all text-sm font-bold"
        >
          <Plus size={16} />
          Nueva Autoridad
        </button>
      </header>

      <section className="px-10 mb-6 flex flex-col gap-4">
        <div className="flex items-center gap-4">
          <div className="relative flex-1 max-w-md">
            <span className="material-symbols-outlined text-[18px] text-stitch-on-surface-variant absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none">
              search
            </span>
            <input
              type="text"
              value={searchValue}
              onChange={(e) => {
                setSearchValue(e.target.value);
                setPageValue(1);
              }}
              placeholder="Buscar por correo o nombre…"
              className="w-full bg-stitch-surface-container-low rounded-[10px] border border-stitch-surface-container-high pl-10 pr-4 py-2.5 text-sm text-white outline-none focus:border-stitch-primary transition-colors placeholder:text-stitch-on-surface-variant"
            />
          </div>
          <select
            value={roleFilter}
            onChange={(e) => {
              setRoleFilter(e.target.value as AdminRole | "ALL");
              setPageValue(1);
            }}
            className="bg-stitch-surface-container-low border border-stitch-surface-container-high rounded-[10px] px-4 py-2.5 text-sm text-white outline-none focus:border-stitch-primary"
          >
            <option value="ALL" className="bg-stitch-surface">
              Todos los roles
            </option>
            <option value="AUTHORITY" className="bg-stitch-surface">
              Autoridad
            </option>
            <option value="ADMIN" className="bg-stitch-surface">
              Administrador
            </option>
          </select>
        </div>
      </section>

      <section className="flex-1 px-10 overflow-hidden flex flex-col min-h-0">
        <div className="flex-1 overflow-auto rounded-xl border border-stitch-surface-container-high bg-stitch-surface-container-low/30">
          <table className="w-full text-left border-collapse">
            <thead className="sticky top-0 bg-stitch-surface-container-low z-10">
              <tr>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                  Nombre
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                  Correo
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                  Rol
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                  Estado
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                  Creado
                </th>
                <th className="px-6 py-4 text-[0.68rem] font-bold uppercase tracking-widest text-stitch-on-surface-variant text-right">
                  Acción
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stitch-surface-container-high">
              {isLoading && (
                <tr>
                  <td
                    colSpan={6}
                    className="px-6 py-12 text-center text-stitch-on-surface-variant text-sm"
                  >
                    Cargando usuarios…
                  </td>
                </tr>
              )}

              {isError && (
                <tr>
                  <td
                    colSpan={6}
                    className="px-6 py-12 text-center text-stitch-error text-sm"
                  >
                    <div className="flex items-center justify-center gap-2">
                      <span className="material-symbols-outlined text-base">
                        error
                      </span>
                      {error instanceof Error
                        ? error.message
                        : "Error al cargar usuarios"}
                    </div>
                  </td>
                </tr>
              )}

              {!isLoading && !isError && data?.items.length === 0 && (
                <tr>
                  <td
                    colSpan={6}
                    className="px-6 py-12 text-center text-stitch-on-surface-variant text-sm"
                  >
                    No hay usuarios con los filtros aplicados.
                  </td>
                </tr>
              )}

              {data?.items.map((user, idx) => (
                <tr
                  key={user.uid}
                  className={`hover:bg-stitch-surface-container-high/20 transition-colors ${
                    idx % 2 === 0 ? "bg-stitch-surface/50" : ""
                  } ${user.disabled ? "opacity-50" : ""}`}
                >
                  <td className="px-6 py-4 text-sm font-semibold text-white">
                    {user.displayName ?? "—"}
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-on-surface-variant">
                    {user.email}
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase border ${
                        user.role === "ADMIN"
                          ? "bg-stitch-primary/10 text-stitch-primary border-stitch-primary/30"
                          : "bg-stitch-tertiary/10 text-stitch-tertiary border-stitch-tertiary/30"
                      }`}
                    >
                      {user.role === "ADMIN" ? "Admin" : "Autoridad"}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`flex items-center gap-1.5 text-xs font-bold ${
                        user.disabled ? "text-stitch-error" : "text-green-500"
                      }`}
                    >
                      <span
                        className={`w-1.5 h-1.5 rounded-full ${
                          user.disabled ? "bg-stitch-error" : "bg-green-500"
                        }`}
                      />
                      {user.disabled ? "Deshabilitado" : "Activo"}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-stitch-on-surface-variant">
                    {formatDate(user.createdAt)}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => openEdit(user)}
                        className="text-xs font-bold text-stitch-primary hover:text-white transition-colors tracking-wider"
                      >
                        Editar
                      </button>
                      <button
                        onClick={() => setDeletingUser(user)}
                        className={`text-xs font-bold tracking-wider transition-colors ${
                          user.disabled
                            ? "text-green-500 hover:text-green-400"
                            : "text-stitch-error hover:text-stitch-error/80"
                        }`}
                      >
                        {user.disabled ? "Rehabilitar" : "Deshabilitar"}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="py-6 flex justify-center">
          <nav className="flex items-center gap-4 text-xs text-stitch-on-surface-variant font-medium">
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              ← Anterior
            </button>
            <span className="text-white">
              Página {page} de {totalPages}
            </span>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              className="hover:text-white transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
            >
              Siguiente →
            </button>
          </nav>
        </div>
      </section>

      <footer className="h-10 border-t border-stitch-surface-container-high bg-stitch-surface-container-low px-10 flex items-center shrink-0">
        <div className="flex items-center gap-2 text-[11px] text-stitch-on-surface-variant">
          <RotateCcw size={14} />
          <span>
            Los cambios en roles requieren que el usuario cierre sesión y vuelva
            a iniciar.
          </span>
        </div>
      </footer>

      {formOpen === "create" && (
        <UserFormDialog
          mode="create"
          onSave={
            handleCreate as (
              input: CreateAdminUserInput | UpdateAdminUserInput,
            ) => void
          }
          onClose={() => setFormOpen(null)}
          isPending={createMutation.isPending}
        />
      )}

      {formOpen === "edit" && editingUser && (
        <UserFormDialog
          mode="edit"
          user={editingUser}
          onSave={
            handleUpdate as (
              input: CreateAdminUserInput | UpdateAdminUserInput,
            ) => void
          }
          onClose={() => {
            setFormOpen(null);
            setEditingUser(null);
          }}
          isPending={updateMutation.isPending}
        />
      )}

      {deletingUser && (
        <UserDeleteDialog
          user={deletingUser}
          onConfirm={handleToggleDisable}
          onClose={() => setDeletingUser(null)}
          isPending={disableMutation.isPending || enableMutation.isPending}
        />
      )}
    </div>
  );
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("es-PE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}
