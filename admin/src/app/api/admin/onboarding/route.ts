import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  try {
    const db = getAdminDb();
    const snap = await db.collection('onboarding_slides').orderBy('order').get();
    const slides = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return NextResponse.json({ ok: true, slides });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

export async function PUT(req: Request) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const body = (await req.json().catch(() => null)) as { slides?: Array<Record<string, unknown>> } | null;
  const slides = body?.slides;
  if (!slides || !Array.isArray(slides)) {
    return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });
  }

  try {
    const db = getAdminDb();
    const batch = db.batch();
    for (let i = 0; i < slides.length; i += 1) {
      const s = slides[i];
      const id = (s.id as string | undefined) || `slide_${i + 1}`;
      const ref = db.collection('onboarding_slides').doc(id);
      batch.set(
        ref,
        {
          order: Number(s.order ?? i),
          isActive: s.isActive ?? true,
          title: s.title ?? { ru: '', en: '' },
          subtitle: s.subtitle ?? { ru: '', en: '' },
          imageAssetPath: (s.imageAssetPath as string | undefined) ?? '',
          backgroundColorHex: (s.backgroundColorHex as string | undefined) ?? '#F0F2F5',
        },
        { merge: true }
      );
    }
    await batch.commit();
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}
