function required(name: string, value: string | undefined) {
  if (!value || value.trim().length === 0) {
    throw new Error(`Missing env: ${name}`);
  }
  return value;
}

export function isAdminSdkConfigured(): boolean {
  return Boolean(
    process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
  );
}

export function getAdminDb() {
  if (!isAdminSdkConfigured()) {
    throw new Error(
      'Firebase Admin SDK не настроен. Нужны FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY.'
    );
  }

  // ВАЖНО: делаем lazy require, чтобы next build не падал на окружении без service account.
  // (Next импортирует route-handlers во время build)
  const adminApp = require('firebase-admin/app') as typeof import('firebase-admin/app');
  const adminFirestore = require('firebase-admin/firestore') as typeof import('firebase-admin/firestore');

  if (!adminApp.getApps().length) {
    const projectId = required('FIREBASE_PROJECT_ID', process.env.FIREBASE_PROJECT_ID);
    const clientEmail = required('FIREBASE_CLIENT_EMAIL', process.env.FIREBASE_CLIENT_EMAIL);
    const privateKeyRaw = required('FIREBASE_PRIVATE_KEY', process.env.FIREBASE_PRIVATE_KEY);
    const privateKey = privateKeyRaw.replace(/\\n/g, '\n');

    adminApp.initializeApp({
      credential: adminApp.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
  }

  return adminFirestore.getFirestore();
}
