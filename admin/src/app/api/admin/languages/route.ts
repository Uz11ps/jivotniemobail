import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

interface LanguageBody {
  code?: string;
  nameRu?: string;
  flag?: string;
  required?: boolean;
  order?: number;
}

export async function GET() {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;
  try {
    const db = getAdminDb();
    const snap = await db.collection('languages').orderBy('order', 'asc').get();
    const items = snap.docs.map((d) => ({ code: d.id, ...d.data() }));
    return NextResponse.json({ ok: true, items });
  } catch (e) {
    return NextResponse.json({ ok: false, error: String(e) }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  const body = (await req.json().catch(() => null)) as LanguageBody | null;
  if (!body || !body.code || !body.nameRu) {
    return NextResponse.json(
      { ok: false, error: 'bad_request', detail: 'code and nameRu are required' },
      { status: 400 }
    );
  }
  const code = body.code.trim().toLowerCase();
  if (!/^[a-z]{2}$/.test(code)) {
    return NextResponse.json(
      { ok: false, error: 'bad_code', detail: 'code must be 2 lowercase letters (ISO 639-1)' },
      { status: 400 }
    );
  }

  try {
    const db = getAdminDb();
    const ref = db.collection('languages').doc(code);
    const existing = await ref.get();
    if (existing.exists) {
      return NextResponse.json({ ok: false, error: 'duplicate', detail: `Language "${code}" already exists` }, { status: 409 });
    }

    // Pick next order if not supplied
    let order = body.order;
    if (typeof order !== 'number') {
      const all = await db.collection('languages').orderBy('order', 'desc').limit(1).get();
      order = all.empty ? 0 : ((all.docs[0].data().order as number) ?? 0) + 1;
    }

    await ref.set({
      nameRu: body.nameRu,
      flag: body.flag || '🏳️',
      required: !!body.required,
      order,
    });
    return NextResponse.json({ ok: true, code, order });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk', detail: String(e) }, { status: 500 });
  }
}
