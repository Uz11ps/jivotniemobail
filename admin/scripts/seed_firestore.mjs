import { initializeApp } from 'firebase/app';
import { collection, doc, getDocs, getFirestore, writeBatch } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyBhL-nacZ_T2FMiLClgx7coFAuU_B6EO4Q',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'deti-zhivotnie-prod.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'deti-zhivotnie-prod',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'deti-zhivotnie-prod.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '854781909795',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:854781909795:web:8cb72a24ef9853e3ea4a96',
};

const PETS_HERO_IMAGE_URL = 'http://168.222.193.86/uploads/categories/hero/pets_hero_static.png';
const FARM_HERO_VIDEO_URL = 'http://168.222.193.86/uploads/categories/hero/farm_hero_loop.mp4';
const VIDEO_BASE_URL = 'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';

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
    heroImageAssetPath: PETS_HERO_IMAGE_URL,
    heroVideoAssetPath: '',
    backgroundColorHex: '#66AEF8',
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
    heroImageAssetPath: '',
    heroVideoAssetPath: FARM_HERO_VIDEO_URL,
    backgroundColorHex: '#F5A623',
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
    heroImageAssetPath: '',
    heroVideoAssetPath: '',
    backgroundColorHex: '#4C8C2B',
  },
  {
    id: 'savannah',
    order: 3,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.savannah',
    priceRub: 199,
    title: { ru: 'Саванна', en: 'Savannah' },
    tabIconAssetPath: '',
    heroImageAssetPath: '',
    heroVideoAssetPath: '',
    backgroundColorHex: '#F7D15E',
  },
  {
    id: 'pond',
    order: 4,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.pond',
    priceRub: 199,
    title: { ru: 'Пруд', en: 'Pond' },
    tabIconAssetPath: '',
    heroImageAssetPath: '',
    heroVideoAssetPath: '',
    backgroundColorHex: '#86D6D9',
  },
  {
    id: 'jungle',
    order: 5,
    isVisible: true,
    isPaid: true,
    iapProductId: 'com.detiiosjivotnie.jungle',
    priceRub: 199,
    title: { ru: 'Джунгли', en: 'Jungle' },
    tabIconAssetPath: '',
    heroImageAssetPath: '',
    heroVideoAssetPath: '',
    backgroundColorHex: '#7FC64F',
  },
];

function animal(id, order, ru, en, bgVideoAssetPath) {
  return {
    id,
    order,
    isVisible: true,
    name: { ru, en },
    topText: { ru, en },
    previewAssetPath: '',
    bgVideoAssetPath: bgVideoAssetPath || '',
    bgAssetPath: '',
    soundAssetPath: '',
    voiceAssetPath: {},
    animationAssetPath: '',
    animationVideoAssetPath: '',
  };
}

const animalsByCategory = {
  pets: [
    animal('cat', 0, 'Кот', 'Cat', `${VIDEO_BASE_URL}/Cat.mp4`),
    animal('rabbit', 1, 'Кролик', 'Rabbit'),
    animal('frog', 2, 'Лягушка', 'Frog'),
    animal('guinea', 3, 'Морская свинка', 'Guinea Pig', `${VIDEO_BASE_URL}/Guinea%20Pig.mp4`),
    animal('turtle', 4, 'Черепаха', 'Turtle'),
    animal('dog', 5, 'Собака', 'Dog'),
    animal('mouse', 6, 'Мышка', 'Mouse'),
    animal('hamster', 7, 'Хомяк', 'Hamster'),
    animal('parrot', 8, 'Попугай', 'Parrot', `${VIDEO_BASE_URL}/Parrot.mp4`),
    animal('ferret', 9, 'Хорек', 'Ferret', `${VIDEO_BASE_URL}/%D0%A1hinchilla.mp4`),
    animal('snail', 10, 'Улитка', 'Snail'),
    animal('white_mouse', 11, 'Белая мышь', 'White mouse', `${VIDEO_BASE_URL}/Guinea%20Pig%202.mp4`),
  ],
  farm: [
    animal('horse', 0, 'Лошадь', 'Horse'),
    animal('pig', 1, 'Свинья', 'Pig'),
    animal('cow', 2, 'Корова', 'Cow'),
    animal('chicken', 3, 'Курица', 'Chicken'),
    animal('sheep', 4, 'Овца', 'Sheep'),
    animal('goat', 5, 'Коза', 'Goat'),
    animal('ostrich', 6, 'Страус', 'Ostrich'),
    animal('duck', 7, 'Утка', 'Duck'),
    animal('deer', 8, 'Олень', 'Deer'),
    animal('bee', 9, 'Пчела', 'Bee'),
    animal('camel', 10, 'Верблюд', 'Camel'),
    animal('lamb', 11, 'Ягненок', 'Lamb'),
  ],
  forest: [
    animal('bear', 0, 'Медведь', 'Bear'),
    animal('wolf', 1, 'Волк', 'Wolf'),
    animal('fox', 2, 'Лиса', 'Fox'),
    animal('owl', 3, 'Сова', 'Owl'),
    animal('squirrel', 4, 'Белка', 'Squirrel'),
    animal('woodpecker', 5, 'Дятел', 'Woodpecker'),
    animal('hedgehog', 6, 'Еж', 'Hedgehog'),
    animal('deer', 7, 'Олень', 'Deer'),
    animal('bird', 8, 'Птичка', 'Bird'),
    animal('beaver', 9, 'Бобр', 'Beaver'),
    animal('crow', 10, 'Ворон', 'Crow'),
    animal('ant', 11, 'Муравей', 'Ant'),
  ],
  savannah: [
    animal('lion', 0, 'Лев', 'Lion'),
    animal('elephant', 1, 'Слон', 'Elephant'),
    animal('leopard', 2, 'Леопард', 'Leopard'),
    animal('rhino', 3, 'Носорог', 'Rhino'),
    animal('giraffe', 4, 'Жираф', 'Giraffe'),
    animal('zebra', 5, 'Зебра', 'Zebra'),
    animal('warthog', 6, 'Бородавочник', 'Warthog'),
    animal('meerkat', 7, 'Сурикат', 'Meerkat'),
    animal('chimpanzee', 8, 'Шимпанзе', 'Chimpanzee'),
    animal('vulture', 9, 'Гриф', 'Vulture'),
    animal('hippo', 10, 'Бегемот', 'Hippo'),
    animal('buffalo', 11, 'Буйвол', 'Buffalo'),
  ],
  pond: [
    animal('dragonfly', 0, 'Стрекоза', 'Dragonfly'),
    animal('crayfish', 1, 'Рак', 'Crayfish'),
    animal('shell', 2, 'Ракушка', 'Shell'),
    animal('newt', 3, 'Тритон', 'Newt'),
    animal('frog', 4, 'Лягушка', 'Frog'),
    animal('beetle', 5, 'Жук', 'Beetle'),
    animal('ant', 6, 'Муравей', 'Ant'),
    animal('duckling', 7, 'Утенок', 'Duckling'),
    animal('heron', 8, 'Цапля', 'Heron'),
    animal('fish', 9, 'Рыба', 'Fish'),
    animal('crocodile', 10, 'Крокодил', 'Crocodile'),
    animal('butterfly', 11, 'Бабочка', 'Butterfly'),
  ],
  jungle: [
    animal('leopard', 0, 'Леопард', 'Leopard'),
    animal('sloth', 1, 'Ленивец', 'Sloth'),
    animal('lizard', 2, 'Ящерица', 'Lizard'),
    animal('crocodile', 3, 'Крокодил', 'Crocodile'),
    animal('capybara', 4, 'Капибара', 'Capybara'),
    animal('anteater', 5, 'Муравьед', 'Anteater'),
    animal('monkey', 6, 'Обезьяна', 'Monkey'),
    animal('tiger', 7, 'Тигр', 'Tiger'),
    animal('bird', 8, 'Птица', 'Bird'),
    animal('mantis', 9, 'Богомол', 'Mantis'),
    animal('chameleon', 10, 'Хамелеон', 'Chameleon'),
    animal('panther', 11, 'Пантера', 'Panther'),
  ],
};

async function syncCategoryAnimals(db, categoryId, animals) {
  const collectionRef = collection(db, 'categories', categoryId, 'animals');
  const snapshot = await getDocs(collectionRef);
  const wantedIds = new Set(animals.map((item) => item.id));
  const batch = writeBatch(db);

  for (const item of snapshot.docs) {
    if (!wantedIds.has(item.id)) {
      batch.delete(item.ref);
    }
  }

  for (const item of animals) {
    const { id, ...payload } = item;
    batch.set(doc(db, 'categories', categoryId, 'animals', id), payload, { merge: true });
  }

  await batch.commit();
}

async function main() {
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  const batch = writeBatch(db);
  for (const item of categories) {
    const { id, ...payload } = item;
    batch.set(doc(db, 'categories', id), payload, { merge: true });
  }
  await batch.commit();

  for (const item of categories) {
    await syncCategoryAnimals(db, item.id, animalsByCategory[item.id] || []);
  }

  console.log(`Catalog synced via Web SDK: ${categories.length} categories`);
}

main().catch((e) => {
  console.error('Seed failed:', e);
  process.exitCode = 1;
});

