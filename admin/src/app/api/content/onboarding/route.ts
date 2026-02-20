import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const FALLBACK = [
  {
    id: 'slide_1',
    order: 0,
    isActive: true,
    title: { ru: "LET'S EXPLORE!", en: "LET'S EXPLORE!" },
    subtitle: { ru: 'Изучаем животных играя', en: 'Learn animals through play' },
    imageAssetPath:
      'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img/onbord%201.png',
    backgroundColorHex: '#F0F2F5',
  },
  {
    id: 'slide_2',
    order: 1,
    isActive: true,
    title: { ru: "LET'S LISTEN!", en: "LET'S LISTEN!" },
    subtitle: { ru: 'Звуки и анимации животных', en: 'Animal sounds and animations' },
    imageAssetPath: 'http://168.222.193.86/uploads/onboarding/seed_slide2.mp4',
    backgroundColorHex: '#F0F2F5',
  },
  {
    id: 'slide_3',
    order: 2,
    isActive: true,
    title: { ru: "LET'S LEARN!", en: "LET'S LEARN!" },
    subtitle: { ru: 'Новые категории из админки', en: 'New categories from admin' },
    imageAssetPath: '',
    backgroundColorHex: '#F0F2F5',
  },
];

export async function GET() {
  try {
    const db = getAdminDb();
    const snap = await db.collection('onboarding_slides').orderBy('order').get();
    const slides = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    if (slides.length > 0) {
      return NextResponse.json({ ok: true, slides });
    }
    return NextResponse.json({ ok: true, slides: FALLBACK, fallback: true });
  } catch {
    return NextResponse.json({ ok: true, slides: FALLBACK, fallback: true });
  }
}
