/**
 * Seed offers + analytics (если пусто).
 *
 * Запуск:
 *   cd admin
 *   node scripts/seed_offers_analytics.mjs
 */

import { initializeApp } from 'firebase/app';
import {
  addDoc,
  collection,
  getDocs,
  getFirestore,
  query,
  limit,
  orderBy,
  writeBatch,
  doc,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyBhL-nacZ_T2FMiLClgx7coFAuU_B6EO4Q',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'deti-zhivotnie-prod.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'deti-zhivotnie-prod',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'deti-zhivotnie-prod.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '854781909795',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:854781909795:web:8cb72a24ef9853e3ea4a96',
};

function ymd(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

async function main() {
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  // Offers
  const offersSnap = await getDocs(query(collection(db, 'offers'), limit(1)));
  if (offersSnap.empty) {
    console.log('Seeding offers...');
    await addDoc(collection(db, 'offers'), {
      isActive: true,
      title: { ru: 'Полный доступ', en: 'Full access' },
      heroAssets: [],
      items: [
        {
          label: { ru: 'Открой все категории', en: 'Unlock all categories' },
          productId: 'com.detiiosjivotnie.full_access',
        },
      ],
      primaryProductId: 'com.detiiosjivotnie.full_access',
    });
    console.log('OK: offers seeded.');
  } else {
    console.log('SKIP: offers already exist.');
  }

  // Analytics daily
  const analyticsCol = collection(db, 'analytics_daily');
  const anSnap = await getDocs(query(analyticsCol, limit(1)));
  if (anSnap.empty) {
    console.log('Seeding analytics_daily...');
    const batch = writeBatch(db);
    const today = new Date();
    for (let i = 13; i >= 0; i -= 1) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const date = ymd(d);
      const ref = doc(db, 'analytics_daily', date);
      // Примерные числа (для отображения графиков). Реальные события добавим позже из мобилки.
      batch.set(ref, {
        date,
        categoryOpens: 50 + (13 - i) * 7,
        animalOpens: 120 + (13 - i) * 11,
        revenueRub: (13 - i) % 4 === 0 ? 199 : 0,
        topCategories: { pets: 20 + (13 - i) * 2, farm: 10 + (13 - i), forest: 8, jungle: 6 },
        topAnimals: { cat: 12 + (13 - i), rabbit: 9, dog: 8, mouse: 7, turtle: 4 },
      });
    }
    await batch.commit();
    console.log('OK: analytics_daily seeded.');
  } else {
    console.log('SKIP: analytics_daily already exist.');
  }

  // Ensure orderBy works (sanity)
  await getDocs(query(analyticsCol, orderBy('date', 'asc'), limit(1)));
}

main().catch((e) => {
  console.error('Seed failed:', e);
  process.exitCode = 1;
});

