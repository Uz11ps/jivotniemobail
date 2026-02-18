import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type Ctx = { params: Promise<{ id: string }> };
const TTL_MS = 60 * 1000;
const animalsCache = new Map<string, { ts: number; data: Array<Record<string, unknown>> }>();

export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  if (!id) {
    return NextResponse.json({ ok: false, error: 'missing_category_id' }, { status: 400 });
  }
  const now = Date.now();
  const cached = animalsCache.get(id);
  if (cached && now - cached.ts < TTL_MS) {
    return NextResponse.json({ ok: true, animals: cached.data, cached: true });
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
    animalsCache.set(id, { ts: now, data: animals });
    return NextResponse.json({ ok: true, animals });
  } catch (e) {
    if (cached) {
      return NextResponse.json({ ok: true, animals: cached.data, cached: true, stale: true });
    }
    return NextResponse.json(
      { ok: false, error: 'server_error', detail: String(e) },
      { status: 500 }
    );
  }
}

