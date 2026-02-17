import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function PATCH(req: Request, ctx: { params: Promise<{ id: string; animalId: string }> }) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const { id: categoryId, animalId } = await ctx.params;
  const body = (await req.json().catch(() => null)) as Record<string, unknown> | null;
  if (!body) return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });

  try {
    const db = getAdminDb();
    await db.collection('categories').doc(categoryId).collection('animals').doc(animalId).set(body, { merge: true });
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

export async function DELETE(_req: Request, ctx: { params: Promise<{ id: string; animalId: string }> }) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const { id: categoryId, animalId } = await ctx.params;
  try {
    const db = getAdminDb();
    await db.collection('categories').doc(categoryId).collection('animals').doc(animalId).delete();
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk_not_configured', detail: String(e) }, { status: 501 });
  }
}

