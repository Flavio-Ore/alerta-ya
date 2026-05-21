/**
 * Setea el custom claim `role` en un usuario Firebase.
 *
 * Uso:
 *   bun run scripts/set-role.ts <email> <AUTHORITY|ADMIN>
 *
 * Requisitos: api/.env con FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.
 *
 * El usuario debe cerrar sesión y volver a iniciar para que el token tenga el claim nuevo.
 */
import { getAuth } from 'firebase-admin/auth';

import { initFirebase } from '../src/core/config/firebase';

const VALID_ROLES = ['AUTHORITY', 'ADMIN'] as const;
type Role = (typeof VALID_ROLES)[number];

function isRole(value: string): value is Role {
  return (VALID_ROLES as readonly string[]).includes(value);
}

async function main(): Promise<void> {
  const [, , email, role] = process.argv;

  if (!email || !role) {
    console.error('Uso: bun run scripts/set-role.ts <email> <AUTHORITY|ADMIN>');
    process.exit(1);
  }

  if (!isRole(role)) {
    console.error(`Rol inválido "${role}". Debe ser uno de: ${VALID_ROLES.join(', ')}`);
    process.exit(1);
  }

  initFirebase();
  const auth = getAuth();

  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, { ...user.customClaims, role });

  const updated = await auth.getUser(user.uid);
  console.log(`✅ Rol "${role}" asignado a ${email}`);
  console.log('   uid:        ', updated.uid);
  console.log('   customClaims:', updated.customClaims);
  console.log('\n⚠️  El usuario debe cerrar sesión y volver a iniciar para que el ID token incluya el claim nuevo.');
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
