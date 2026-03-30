import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const TTL_MS = 60 * 1000;
let cache: { ts: number; data: Array<Record<string, unknown>> } | null = null;
const PETS_HERO_IMAGE_URL =
  'http://168.222.193.86/uploads/categories/hero/pets_hero_static.png';
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
    heroVideoAssetPath: 'http://168.222.193.86/uploads/categories/hero/farm_hero_loop.mp4',
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

    const categories = snap.docs.map((d) => {
      const row = { id: d.id, ...d.data() } as Record<string, unknown>;
      if (d.id === 'pets') {
        row.heroImageAssetPath = PETS_HERO_IMAGE_URL;
        row.heroVideoAssetPath = '';
      }
      return row;
    });
    const present = new Set(categories.map((item) => String(item.id ?? '')));
    const merged = [
      ...categories,
      ...FALLBACK_CATEGORIES.filter((item) => !present.has(String(item.id ?? ''))),
    ].sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
    cache = { ts: now, data: merged };
    return NextResponse.json({ ok: true, categories: merged });
  } catch {
    if (cache) {
      return NextResponse.json({ ok: true, categories: cache.data, cached: true, stale: true });
    }
    return NextResponse.json({ ok: true, categories: FALLBACK_CATEGORIES, fallback: true });
  }
}

