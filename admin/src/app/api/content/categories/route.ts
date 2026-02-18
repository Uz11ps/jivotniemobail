import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const TTL_MS = 60 * 1000;
let cache: { ts: number; data: Array<Record<string, unknown>> } | null = null;

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

    const categories = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    cache = { ts: now, data: categories };
    return NextResponse.json({ ok: true, categories });
  } catch (e) {
    if (cache) {
      return NextResponse.json({ ok: true, categories: cache.data, cached: true, stale: true });
    }
    return NextResponse.json(
      { ok: false, error: 'server_error', detail: String(e) },
      { status: 500 }
    );
  }
}

