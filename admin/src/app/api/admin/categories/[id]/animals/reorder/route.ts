import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const { id: categoryId } = await ctx.params;
  const body = (await req.json().catch(() => null)) as { ids?: string[] } | null;
  if (!body?.ids || !Array.isArray(body.ids)) {
    return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });
  }

  try {
    const db = getAdminDb();
    const batch = db.batch();
    body.ids.forEach((id, index) => {
      batch.update(db.collection('categories').doc(categoryId).collection('animals').doc(id), { order: index });
    });
    await batch.commit();
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

