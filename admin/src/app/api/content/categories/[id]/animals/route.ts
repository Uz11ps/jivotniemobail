import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type Ctx = { params: Promise<{ id: string }> };
const TTL_MS = 60 * 1000;
const animalsCache = new Map<string, { ts: number; data: Array<Record<string, unknown>> }>();
const FALLBACK_VIDEO_BASE_URL = 'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';
const animal = (
  id: string,
  order: number,
  ru: string,
  en: string,
  bgVideoAssetPath?: string,
): Record<string, unknown> => ({
  id,
  order,
  isVisible: true,
  name: { ru, en },
  topText: { ru, en },
  ...(bgVideoAssetPath ? { bgVideoAssetPath } : {}),
});
const FALLBACK_ANIMALS: Record<string, Array<Record<string, unknown>>> = {
  pets: [
    animal('cat', 0, 'Кот', 'Cat', `${FALLBACK_VIDEO_BASE_URL}/Cat.mp4`),
    animal('rabbit', 1, 'Кролик', 'Rabbit'),
    animal('frog', 2, 'Лягушка', 'Frog'),
    animal('guinea', 3, 'Морская свинка', 'Guinea Pig'),
    animal('turtle', 4, 'Черепаха', 'Turtle'),
    animal('dog', 5, 'Собака', 'Dog'),
    animal('mouse', 6, 'Мышка', 'Mouse'),
    animal('hamster', 7, 'Хомяк', 'Hamster'),
    animal('parrot', 8, 'Попугай', 'Parrot'),
    animal('ferret', 9, 'Хорек', 'Ferret'),
    animal('snail', 10, 'Улитка', 'Snail'),
    animal('white_mouse', 11, 'Белая мышь', 'White mouse'),
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

export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  if (!id) {
    return NextResponse.json({ ok: false, error: 'missing_category_id' }, { status: 400 });
  }
  const now = Date.now();
  const cached = animalsCache.get(id);
  if (cached && now - cached.ts < TTL_MS) {
    return NextResponse.json({ ok: true, animals: cached.data, cached: true });
  }

  try {
    const db = getAdminDb();
    const snap = await db
      .collection('categories')
      .doc(id)
      .collection('animals')
      .where('isVisible', '==', true)
      .orderBy('order')
      .get();

    const animals = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const result = animals.length > 0 ? animals : (FALLBACK_ANIMALS[id] ?? []);
    animalsCache.set(id, { ts: now, data: result });
    return NextResponse.json({ ok: true, animals: result, fallback: animals.length === 0 });
  } catch {
    if (cached) {
      return NextResponse.json({ ok: true, animals: cached.data, cached: true, stale: true });
    }
    return NextResponse.json({ ok: true, animals: FALLBACK_ANIMALS[id] ?? [], fallback: true });
  }
}

