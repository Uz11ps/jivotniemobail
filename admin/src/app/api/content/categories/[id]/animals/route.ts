import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type Ctx = { params: Promise<{ id: string }> };

export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  if (!id) {
    return NextResponse.json({ ok: false, error: 'missing_category_id' }, { status: 400 });
  }

  try {
    const db = getAdminDb();
    const snap = await db
      .collection('categories')
      .doc(id)
      .collection('animals')
      .where('isVisible', '==', true)
      .orderBy('order')
      .get();

    const animals = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return NextResponse.json({ ok: true, animals });
  } catch (e) {
    return NextResponse.json(
      { ok: false, error: 'server_error', detail: String(e) },
      { status: 500 }
    );
  }
}

