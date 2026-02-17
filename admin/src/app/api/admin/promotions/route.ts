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
    const snap = await db.collection('promotions').orderBy('order', 'asc').get();
    const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return NextResponse.json({ ok: true, items });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

export async function POST(req: Request) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const body = (await req.json().catch(() => null)) as Record<string, unknown> | null;
  if (!body) return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });

  try {
    const db = getAdminDb();
    const ref = await db.collection('promotions').add(body);
    return NextResponse.json({ ok: true, id: ref.id });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

