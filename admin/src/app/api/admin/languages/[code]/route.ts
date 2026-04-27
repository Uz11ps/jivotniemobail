import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function PATCH(req: Request, ctx: { params: Promise<{ code: string }> }) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;
  const { code } = await ctx.params;
  if (!/^[a-z]{2}$/.test(code)) {
    return NextResponse.json({ ok: false, error: 'bad_code' }, { status: 400 });
  }
  const body = (await req.json().catch(() => null)) as Record<string, unknown> | null;
  if (!body) return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });

  // Strip code from updates if present (we identify by URL).
  delete (body as Record<string, unknown>).code;

  try {
    const db = getAdminDb();
    await db.collection('languages').doc(code).update(body);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk', detail: String(e) }, { status: 500 });
  }
}

export async function DELETE(_: Request, ctx: { params: Promise<{ code: string }> }) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;
  const { code } = await ctx.params;
  try {
    const db = getAdminDb();
    await db.collection('languages').doc(code).delete();
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk', detail: String(e) }, { status: 500 });
  }
}
