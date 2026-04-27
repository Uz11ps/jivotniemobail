import { NextResponse } from 'next/server';
import { requireAdminSession } from '@/lib/requireAdminSession';
import { getAdminDb } from '@/lib/firebase/admin';
import { DEFAULT_LANGUAGES } from '@/lib/languages';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/** Sets up the 15 default languages. Idempotent: skips existing docs. */
export async function POST() {
  const authRes = await requireAdminSession();
  if (authRes) return authRes;

  try {
    const db = getAdminDb();
    const batch = db.batch();
    let created = 0;
    let skipped = 0;
    for (let i = 0; i < DEFAULT_LANGUAGES.length; i++) {
      const lang = DEFAULT_LANGUAGES[i];
      const ref = db.collection('languages').doc(lang.code);
      const existing = await ref.get();
      if (existing.exists) {
        skipped++;
        continue;
      }
      batch.set(ref, {
        nameRu: lang.nameRu,
        flag: lang.flag,
        required: !!lang.required,
        order: i,
      });
      created++;
    }
    if (created > 0) await batch.commit();
    return NextResponse.json({ ok: true, created, skipped });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'admin_sdk', detail: String(e) }, { status: 500 });
  }
}
