import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const TTL_MS = 60 * 1000;
let cache: { ts: number; data: Array<Record<string, unknown>> } | null = null;
const FALLBACK_CATEGORIES: Array<Record<string, unknown>> = [
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

export async function GET() {
  const now = Date.now();
  if (cache && now - cache.ts < TTL_MS) {
    return NextResponse.json({ ok: true, categories: cache.data, cached: true });
  }

  try {
    const db = getAdminDb();
    const snap = await db
      .collection('categories')
      .where('isVisible', '==', true)
      .orderBy('order')
      .get();

    const categories = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    cache = { ts: now, data: categories };
    return NextResponse.json({ ok: true, categories });
  } catch {
    if (cache) {
      return NextResponse.json({ ok: true, categories: cache.data, cached: true, stale: true });
    }
    return NextResponse.json({ ok: true, categories: FALLBACK_CATEGORIES, fallback: true });
  }
}

