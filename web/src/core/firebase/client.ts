import { initializeApp, type FirebaseApp } from 'firebase/app';
import { getAuth, setPersistence, browserLocalPersistence, type Auth } from 'firebase/auth';

const firebaseConfig = {
  apiKey:            import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain:        import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId:         import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket:     import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId:             import.meta.env.VITE_FIREBASE_APP_ID,
};

const REQUIRED_VARS = ['apiKey', 'authDomain', 'projectId', 'appId'] as const;
const missing = REQUIRED_VARS.filter((k) => !firebaseConfig[k]);

export const firebaseConfigMissing: string[] = missing.map(
  (k) => `VITE_FIREBASE_${k.replace(/([A-Z])/g, '_$1').toUpperCase()}`,
);

export const firebaseAvailable = missing.length === 0;

let app:  FirebaseApp | null = null;
let auth: Auth | null = null;

if (firebaseAvailable) {
  app  = initializeApp(firebaseConfig);
  auth = getAuth(app);
  void setPersistence(auth, browserLocalPersistence);
} else {
  // eslint-disable-next-line no-console
  console.error(
    '[AlertaYa] Firebase NO está configurado. Faltan variables en web/.env:\n' +
      firebaseConfigMissing.map((v) => `  - ${v}`).join('\n') +
      '\nCopiá web/.env.example a web/.env y completá con las credenciales de Firebase Console.',
  );
}

export const firebaseApp  = app;
export const firebaseAuth = auth;
