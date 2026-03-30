import { Animal, Category } from '@/types';

const petsHeroImageUrl = 'http://168.222.193.86/uploads/categories/hero/pets_hero_static.png';
const farmHeroVideoUrl = 'http://168.222.193.86/uploads/categories/hero/farm_hero_loop.mp4';
const videoBaseUrl = 'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';

export const defaultCategories: Category[] = [
  {
    id: 'pets',
    order: 0,
    isVisible: true,
    isPaid: false,
    iapProductId: null,
    priceRub: null,
    title: { ru: 'Питомцы', en: 'Pets' },
    tabIconAssetPath: '',
    heroImageAssetPath: petsHeroImageUrl,
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
    heroVideoAssetPath: farmHeroVideoUrl,
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

function createAnimal(
  id: string,
  order: number,
  ru: string,
  en: string,
  bgVideoAssetPath?: string,
): Animal {
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

export const defaultAnimalsByCategory: Record<string, Animal[]> = {
  pets: [
    createAnimal('cat', 0, 'Кот', 'Cat', `${videoBaseUrl}/Cat.mp4`),
    createAnimal('rabbit', 1, 'Кролик', 'Rabbit'),
    createAnimal('frog', 2, 'Лягушка', 'Frog'),
    createAnimal('guinea', 3, 'Морская свинка', 'Guinea Pig', `${videoBaseUrl}/Guinea%20Pig.mp4`),
    createAnimal('turtle', 4, 'Черепаха', 'Turtle'),
    createAnimal('dog', 5, 'Собака', 'Dog'),
    createAnimal('mouse', 6, 'Мышка', 'Mouse'),
    createAnimal('hamster', 7, 'Хомяк', 'Hamster'),
    createAnimal('parrot', 8, 'Попугай', 'Parrot', `${videoBaseUrl}/Parrot.mp4`),
    createAnimal('ferret', 9, 'Хорек', 'Ferret', `${videoBaseUrl}/%D0%A1hinchilla.mp4`),
    createAnimal('snail', 10, 'Улитка', 'Snail'),
    createAnimal('white_mouse', 11, 'Белая мышь', 'White mouse', `${videoBaseUrl}/Guinea%20Pig%202.mp4`),
  ],
  farm: [
    createAnimal('horse', 0, 'Лошадь', 'Horse'),
    createAnimal('pig', 1, 'Свинья', 'Pig'),
    createAnimal('cow', 2, 'Корова', 'Cow'),
    createAnimal('chicken', 3, 'Курица', 'Chicken'),
    createAnimal('sheep', 4, 'Овца', 'Sheep'),
    createAnimal('goat', 5, 'Коза', 'Goat'),
    createAnimal('ostrich', 6, 'Страус', 'Ostrich'),
    createAnimal('duck', 7, 'Утка', 'Duck'),
    createAnimal('deer', 8, 'Олень', 'Deer'),
    createAnimal('bee', 9, 'Пчела', 'Bee'),
    createAnimal('camel', 10, 'Верблюд', 'Camel'),
    createAnimal('lamb', 11, 'Ягненок', 'Lamb'),
  ],
  forest: [
    createAnimal('bear', 0, 'Медведь', 'Bear'),
    createAnimal('wolf', 1, 'Волк', 'Wolf'),
    createAnimal('fox', 2, 'Лиса', 'Fox'),
    createAnimal('owl', 3, 'Сова', 'Owl'),
    createAnimal('squirrel', 4, 'Белка', 'Squirrel'),
    createAnimal('woodpecker', 5, 'Дятел', 'Woodpecker'),
    createAnimal('hedgehog', 6, 'Еж', 'Hedgehog'),
    createAnimal('deer', 7, 'Олень', 'Deer'),
    createAnimal('bird', 8, 'Птичка', 'Bird'),
    createAnimal('beaver', 9, 'Бобр', 'Beaver'),
    createAnimal('crow', 10, 'Ворон', 'Crow'),
    createAnimal('ant', 11, 'Муравей', 'Ant'),
  ],
  savannah: [
    createAnimal('lion', 0, 'Лев', 'Lion'),
    createAnimal('elephant', 1, 'Слон', 'Elephant'),
    createAnimal('leopard', 2, 'Леопард', 'Leopard'),
    createAnimal('rhino', 3, 'Носорог', 'Rhino'),
    createAnimal('giraffe', 4, 'Жираф', 'Giraffe'),
    createAnimal('zebra', 5, 'Зебра', 'Zebra'),
    createAnimal('warthog', 6, 'Бородавочник', 'Warthog'),
    createAnimal('meerkat', 7, 'Сурикат', 'Meerkat'),
    createAnimal('chimpanzee', 8, 'Шимпанзе', 'Chimpanzee'),
    createAnimal('vulture', 9, 'Гриф', 'Vulture'),
    createAnimal('hippo', 10, 'Бегемот', 'Hippo'),
    createAnimal('buffalo', 11, 'Буйвол', 'Buffalo'),
  ],
  pond: [
    createAnimal('dragonfly', 0, 'Стрекоза', 'Dragonfly'),
    createAnimal('crayfish', 1, 'Рак', 'Crayfish'),
    createAnimal('shell', 2, 'Ракушка', 'Shell'),
    createAnimal('newt', 3, 'Тритон', 'Newt'),
    createAnimal('frog', 4, 'Лягушка', 'Frog'),
    createAnimal('beetle', 5, 'Жук', 'Beetle'),
    createAnimal('ant', 6, 'Муравей', 'Ant'),
    createAnimal('duckling', 7, 'Утенок', 'Duckling'),
    createAnimal('heron', 8, 'Цапля', 'Heron'),
    createAnimal('fish', 9, 'Рыба', 'Fish'),
    createAnimal('crocodile', 10, 'Крокодил', 'Crocodile'),
    createAnimal('butterfly', 11, 'Бабочка', 'Butterfly'),
  ],
  jungle: [
    createAnimal('leopard', 0, 'Леопард', 'Leopard'),
    createAnimal('sloth', 1, 'Ленивец', 'Sloth'),
    createAnimal('lizard', 2, 'Ящерица', 'Lizard'),
    createAnimal('crocodile', 3, 'Крокодил', 'Crocodile'),
    createAnimal('capybara', 4, 'Капибара', 'Capybara'),
    createAnimal('anteater', 5, 'Муравьед', 'Anteater'),
    createAnimal('monkey', 6, 'Обезьяна', 'Monkey'),
    createAnimal('tiger', 7, 'Тигр', 'Tiger'),
    createAnimal('bird', 8, 'Птица', 'Bird'),
    createAnimal('mantis', 9, 'Богомол', 'Mantis'),
    createAnimal('chameleon', 10, 'Хамелеон', 'Chameleon'),
    createAnimal('panther', 11, 'Пантера', 'Panther'),
  ],
};

export function mergeCategoriesWithDefaults(source: Category[]): Category[] {
  const byId = new Map<string, Category>();

  for (const item of defaultCategories) {
    if (item.id) byId.set(item.id, item);
  }

  for (const item of source) {
    if (!item.id) continue;
    byId.set(item.id, {
      ...byId.get(item.id),
      ...item,
      title: item.title ?? byId.get(item.id)?.title ?? { ru: '', en: '' },
    });
  }

  return Array.from(byId.values()).sort((a, b) => a.order - b.order);
}

export function getDefaultAnimals(categoryId: string): Animal[] {
  return defaultAnimalsByCategory[categoryId] ?? [];
}

export function mergeAnimalsWithDefaults(categoryId: string, source: Animal[]): Animal[] {
  const defaults = getDefaultAnimals(categoryId);
  const byId = new Map<string, Animal>();

  for (const item of defaults) {
    if (item.id) byId.set(item.id, item);
  }

  for (const item of source) {
    if (!item.id) continue;
    byId.set(item.id, {
      ...byId.get(item.id),
      ...item,
      name: item.name ?? byId.get(item.id)?.name ?? { ru: '', en: '' },
      topText: item.topText ?? byId.get(item.id)?.topText ?? item.name ?? { ru: '', en: '' },
      voiceAssetPath: item.voiceAssetPath ?? byId.get(item.id)?.voiceAssetPath ?? {},
    });
  }

  return Array.from(byId.values()).sort((a, b) => a.order - b.order);
}
