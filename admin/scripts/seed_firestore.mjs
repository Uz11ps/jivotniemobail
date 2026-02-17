/**
 * Инициализация Firestore начальными данными (категории/животные).
 *
 * Запуск:
 *   cd admin
 *   node scripts/seed_firestore.mjs
 *
 * Важно:
 * - Скрипт использует Web Firebase SDK (apiKey) и подчиняется Firestore rules.
 * - Пишем документы с фиксированными id (pets/farm/forest/jungle), как в Flutter mock.
 */

import { initializeApp } from 'firebase/app';
import {
  doc,
  getFirestore,
  setDoc,
  writeBatch,
  collection,
  getDocs,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyBhL-nacZ_T2FMiLClgx7coFAuU_B6EO4Q',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'deti-zhivotnie-prod.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'deti-zhivotnie-prod',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'deti-zhivotnie-prod.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '854781909795',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:854781909795:web:8cb72a24ef9853e3ea4a96',
};

const categories = [
  {
    id: 'pets',
    order: 0,
    isVisible: true,
    isPaid: false,
    iapProductId: null,
    priceRub: null,
    title: { ru: 'Питомцы', en: 'Pets' },
    tabIconAssetPath: '',
  },
  {
    id: 'farm',
    order: 1,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.farm',
    priceRub: 199,
    title: { ru: 'Ферма', en: 'Farm' },
    tabIconAssetPath: '',
  },
  {
    id: 'forest',
    order: 2,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.forest',
    priceRub: 199,
    title: { ru: 'Лес', en: 'Forest' },
    tabIconAssetPath: '',
  },
  {
    id: 'jungle',
    order: 3,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.jungle',
    priceRub: 199,
    title: { ru: 'Джунгли', en: 'Jungle' },
    tabIconAssetPath: '',
  },
];

const animalsByCategory = {
  pets: [
    { id: 'cat', order: 0, name: { ru: 'Кот', en: 'Cat' }, topText: { ru: 'Кот/кошка', en: 'Cat' } },
    { id: 'rabbit', order: 1, name: { ru: 'Кролик', en: 'Rabbit' }, topText: { ru: 'Кролик', en: 'Rabbit' } },
    { id: 'frog', order: 2, name: { ru: 'Лягушка', en: 'Frog' }, topText: { ru: 'Лягушка', en: 'Frog' } },
    { id: 'guinea', order: 3, name: { ru: 'Морская свинка', en: 'Guinea Pig' }, topText: { ru: 'Морская свинка', en: 'Guinea pig' } },
    { id: 'turtle', order: 4, name: { ru: 'Черепаха', en: 'Turtle' }, topText: { ru: 'Черепаха', en: 'Turtle' } },
    { id: 'dog', order: 5, name: { ru: 'Собака', en: 'Dog' }, topText: { ru: 'Собака', en: 'Dog' } },
    { id: 'mouse', order: 6, name: { ru: 'Мышка', en: 'Mouse' }, topText: { ru: 'Мышка', en: 'Mouse' } },
    { id: 'hamster', order: 7, name: { ru: 'Хомяк', en: 'Hamster' }, topText: { ru: 'Хомяк', en: 'Hamster' } },
    { id: 'parrot', order: 8, name: { ru: 'Попугай', en: 'Parrot' }, topText: { ru: 'Попугай', en: 'Parrot' } },
    { id: 'ferret', order: 9, name: { ru: 'Хорек', en: 'Ferret' }, topText: { ru: 'Хорек', en: 'Ferret' } },
    { id: 'snail', order: 10, name: { ru: 'Улитка', en: 'Snail' }, topText: { ru: 'Улитка', en: 'Snail' } },
    { id: 'white_mouse', order: 11, name: { ru: 'Белая мышь', en: 'White mouse' }, topText: { ru: 'Белая мышь', en: 'White mouse' } },
  ],
  farm: [
    { id: 'cow', order: 0, name: { ru: 'Корова', en: 'Cow' } },
    { id: 'pig', order: 1, name: { ru: 'Свинья', en: 'Pig' } },
    { id: 'goat', order: 2, name: { ru: 'Коза', en: 'Goat' } },
  ],
};

function normalizeAnimal(a) {
  const topText = a.topText || a.name;
  return {
    order: a.order,
    isVisible: true,
    name: a.name,
    topText,
    // Медиа пока пустое: можно заполнить в админке через upload на сервер.
    previewAssetPath: '',
    bgVideoAssetPath: '',
    bgAssetPath: '',
    soundAssetPath: '',
  };
}

async function main() {
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  // Если категории уже существуют — не трогаем (чтобы не затирать ручные правки).
  const existing = await getDocs(collection(db, 'categories'));
  if (!existing.empty) {
    console.log('SKIP: categories already exist in Firestore.');
    return;
  }

  console.log('Seeding categories + animals...');
  const batch = writeBatch(db);

  for (const c of categories) {
    const ref = doc(db, 'categories', c.id);
    batch.set(ref, {
      order: c.order,
      isVisible: c.isVisible,
      isPaid: c.isPaid,
      iapProductId: c.iapProductId ?? null,
      priceRub: c.priceRub ?? null,
      title: c.title,
      tabIconAssetPath: c.tabIconAssetPath || '',
    });

    const animals = animalsByCategory[c.id] || [];
    for (const a of animals) {
      const aref = doc(db, 'categories', c.id, 'animals', a.id);
      batch.set(aref, normalizeAnimal(a));
    }
  }

  await batch.commit();
  console.log('OK: seed complete.');
}

main().catch((e) => {
  console.error('Seed failed:', e);
  process.exitCode = 1;
});

