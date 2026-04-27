import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const body = (await req.json().catch(() => null)) as { items?: Array<{ code: string; order: number }> } | null;
  if (!body?.items?.length) {
    return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });
  }

  try {
    const db = getAdminDb();
    const batch = db.batch();
    for (const item of body.items) {
      const code = String(item.code).toLowerCase();
      if (!/^[a-z]{2}$/.test(code)) continue;
      batch.update(db.collection('languages').doc(code), { order: item.order });
    }
    await batch.commit();
    return NextResponse.json({ ok: true, count: body.items.length });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk', detail: String(e) }, { status: 500 });
  }
}
