/**
 * Crea usuarios de prueba en Firebase Auth y asigna sus roles.
 *
 * Uso:
 *   bun run scripts/setup-test-users.ts
 *
 * Requisitos: api/.env con credenciales Firebase configuradas.
 */
import { getAuth } from 'firebase-admin/auth';
import { initFirebase } from '../src/core/config/firebase';

const TEST_USERS = [
  {
    email: 'admin@alertaya.pe',
    password: 'Admin123!',
    displayName: 'Admin AlertaYa',
    role: 'ADMIN' as const,
  },
  {
    email: 'autoridad@alertaya.pe',
    password: 'Auth123!',
    displayName: 'Autoridad Lima',
    role: 'AUTHORITY' as const,
  },
];

async function main(): Promise<void> {
  initFirebase();
  const auth = getAuth();

  for (const u of TEST_USERS) {
    try {
      const existing = await auth.getUserByEmail(u.email);
      // Ya existe — solo actualizar claims por si acaso
      await auth.setCustomUserClaims(existing.uid, { ...existing.customClaims, role: u.role });
      console.log(`✅ ${u.email} — ya existía, rol actualizado a ${u.role}`);
    } catch {
      // No existe — crear
      const user = await auth.createUser({
        email: u.email,
        password: u.password,
        displayName: u.displayName,
      });
      await auth.setCustomUserClaims(user.uid, { role: u.role });
      console.log(`✅ ${u.email} — creado con rol ${u.role}`);
    }
  }

  console.log('\nUsuarios listos:');
  console.log('  admin@alertaya.pe / Admin123!     → ADMIN');
  console.log('  autoridad@alertaya.pe / Auth123!  → AUTHORITY');
  console.log('\n⚠️  Inicia sesión en http://localhost:5173/auth/login');
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
