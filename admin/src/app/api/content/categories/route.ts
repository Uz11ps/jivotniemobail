import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const db = getAdminDb();
    const snap = await db
      .collection('categories')
      .where('isVisible', '==', true)
      .orderBy('order')
      .get();

    const categories = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return NextResponse.json({ ok: true, categories });
  } catch (e) {
    return NextResponse.json(
      { ok: false, error: 'server_error', detail: String(e) },
      { status: 500 }
    );
  }
}

