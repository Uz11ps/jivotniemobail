import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type Ctx = { params: Promise<{ id: string }> };
const TTL_MS = 60 * 1000;
const animalsCache = new Map<string, { ts: number; data: Array<Record<string, unknown>> }>();
const FALLBACK_ANIMALS: Record<string, Array<Record<string, unknown>>> = {
  pets: [
    { id: 'cat', order: 0, isVisible: true, name: { ru: 'Кот', en: 'Cat' }, topText: { ru: 'Кот/кошка', en: 'Cat' } },
    { id: 'rabbit', order: 1, isVisible: true, name: { ru: 'Кролик', en: 'Rabbit' }, topText: { ru: 'Кролик', en: 'Rabbit' } },
    { id: 'frog', order: 2, isVisible: true, name: { ru: 'Лягушка', en: 'Frog' }, topText: { ru: 'Лягушка', en: 'Frog' } },
    {
      id: 'guinea',
      order: 3,
      isVisible: true,
      name: { ru: 'Морская свинка', en: 'Guinea Pig' },
      topText: { ru: 'Морская свинка', en: 'Guinea pig' },
    },
  ],
  farm: [
    { id: 'cow', order: 0, isVisible: true, name: { ru: 'Корова', en: 'Cow' }, topText: { ru: 'Корова', en: 'Cow' } },
    { id: 'pig', order: 1, isVisible: true, name: { ru: 'Свинья', en: 'Pig' }, topText: { ru: 'Свинья', en: 'Pig' } },
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

