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
    heroImageAssetPath: 'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img/%D0%93%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F%20%D0%BF%D0%B8%D0%BA%D1%87%D0%B0.png',
    heroVideoAssetPath: 'http://168.222.193.86/uploads/onboarding/seed_slide2.mp4',
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
    heroVideoAssetPath: '',
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
    backgroundColorHex: '#66AEF8',
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
    heroImageAssetPath: '',
    heroVideoAssetPath: '',
    backgroundColorHex: '#66AEF8',
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

