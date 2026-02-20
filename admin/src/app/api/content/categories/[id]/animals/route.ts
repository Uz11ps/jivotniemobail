import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type Ctx = { params: Promise<{ id: string }> };
const TTL_MS = 60 * 1000;
const animalsCache = new Map<string, { ts: number; data: Array<Record<string, unknown>> }>();
const FALLBACK_VIDEO_BASE_URL = 'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';
const FALLBACK_ANIMALS: Record<string, Array<Record<string, unknown>>> = {
  pets: [
    {
      id: 'cat',
      order: 0,
      isVisible: true,
      name: { ru: 'Кот', en: 'Cat' },
      topText: { ru: 'Кот/кошка', en: 'Cat' },
      bgVideoAssetPath: `${FALLBACK_VIDEO_BASE_URL}/Cat.mp4`,
    },
    { id: 'rabbit', order: 1, isVisible: true, name: { ru: 'Кролик', en: 'Rabbit' }, topText: { ru: 'Кролик', en: 'Rabbit' } },
    { id: 'frog', order: 2, isVisible: true, name: { ru: 'Лягушка', en: 'Frog' }, topText: { ru: 'Лягушка', en: 'Frog' } },
    {
      id: 'guinea',
      order: 3,
      isVisible: true,
      name: { ru: 'Морская свинка', en: 'Guinea Pig' },
      topText: { ru: 'Морская свинка', en: 'Guinea pig' },
    },
    { id: 'turtle', order: 4, isVisible: true, name: { ru: 'Черепаха', en: 'Turtle' }, topText: { ru: 'Черепаха', en: 'Turtle' } },
    { id: 'dog', order: 5, isVisible: true, name: { ru: 'Собака', en: 'Dog' }, topText: { ru: 'Собака', en: 'Dog' } },
    { id: 'mouse', order: 6, isVisible: true, name: { ru: 'Мышка', en: 'Mouse' }, topText: { ru: 'Мышка', en: 'Mouse' } },
    { id: 'hamster', order: 7, isVisible: true, name: { ru: 'Хомяк', en: 'Hamster' }, topText: { ru: 'Хомяк', en: 'Hamster' } },
    { id: 'parrot', order: 8, isVisible: true, name: { ru: 'Попугай', en: 'Parrot' }, topText: { ru: 'Попугай', en: 'Parrot' } },
    { id: 'ferret', order: 9, isVisible: true, name: { ru: 'Хорек', en: 'Ferret' }, topText: { ru: 'Хорек', en: 'Ferret' } },
    { id: 'snail', order: 10, isVisible: true, name: { ru: 'Улитка', en: 'Snail' }, topText: { ru: 'Улитка', en: 'Snail' } },
    {
      id: 'white_mouse',
      order: 11,
      isVisible: true,
      name: { ru: 'Белая мышь', en: 'White mouse' },
      topText: { ru: 'Белая мышь', en: 'White mouse' },
    },
  ],
  farm: [
    { id: 'cow', order: 0, isVisible: true, name: { ru: 'Корова', en: 'Cow' }, topText: { ru: 'Корова', en: 'Cow' } },
    {
      id: 'pig',
      order: 1,
      isVisible: true,
      name: { ru: 'Свинья', en: 'Pig' },
      topText: { ru: 'Свинья', en: 'Pig' },
      bgVideoAssetPath: 'http://168.222.193.86/uploads/animals/backgroundVideo/seed_pig.mp4',
    },
    { id: 'goat', order: 2, isVisible: true, name: { ru: 'Коза', en: 'Goat' }, topText: { ru: 'Коза', en: 'Goat' } },
  ],
  forest: [],
  jungle: [],
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
    animalsCache.set(id, { ts: now, data: animals });
    return NextResponse.json({ ok: true, animals });
  } catch {
    if (cached) {
      return NextResponse.json({ ok: true, animals: cached.data, cached: true, stale: true });
    }
    return NextResponse.json({ ok: true, animals: FALLBACK_ANIMALS[id] ?? [], fallback: true });
  }
}

