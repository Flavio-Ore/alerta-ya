import { Request, Response, NextFunction } from 'express';

import { AppError } from '../../../core/errors/AppError';
import {
  createFirebaseUser,
  listFirebaseUsers,
  getFirebaseUser,
  updateFirebaseUser,
  disableFirebaseUser,
  enableFirebaseUser,
} from '../infrastructure/firebase-admin.repository';
import type { CreateUserInput, UpdateUserInput, ListUsersQuery } from './admin.schema';

export async function listUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const query = req.query as unknown as ListUsersQuery;
    const result = await listFirebaseUsers({
      search: query.search,
      page: query.page ?? 1,
      pageSize: query.pageSize ?? 20,
      role: query.role,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function getUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await getFirebaseUser(req.params['uid']!);
    if (!user) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }
    res.json(user);
  } catch (err) {
    next(err);
  }
}

export async function createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = req.body as CreateUserInput;

    const exists = await getFirebaseUser(req.body['email'] ?? '');
    if (exists) {
      next(new AppError(409, 'Ya existe un usuario con ese correo'));
      return;
    }

    const user = await createFirebaseUser(body);
    res.status(201).json(user);
  } catch (err: unknown) {
    if (err instanceof Error && 'code' in err && (err as Record<string, unknown>)['code'] === 'auth/email-already-exists') {
      next(new AppError(409, 'Ya existe un usuario con ese correo'));
      return;
    }
    if (err instanceof Error && 'code' in err && (err as Record<string, unknown>)['code'] === 'auth/invalid-password') {
      next(new AppError(400, 'La contraseña debe tener al menos 6 caracteres'));
      return;
    }
    next(err);
  }
}

export async function updateUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = req.body as UpdateUserInput;
    const user = await updateFirebaseUser(req.params['uid']!, body);
    if (!user) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }
    res.json(user);
  } catch (err) {
    next(err);
  }
}

export async function disableUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const uid = req.params['uid']!;

    if (uid === req.user?.uid) {
      next(new AppError(400, 'No puedes deshabilitar tu propia cuenta'));
      return;
    }

    const ok = await disableFirebaseUser(uid);
    if (!ok) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

export async function enableUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const ok = await enableFirebaseUser(req.params['uid']!);
    if (!ok) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}
