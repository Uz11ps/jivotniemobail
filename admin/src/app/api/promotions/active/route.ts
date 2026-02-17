import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type PromotionDoc = {
  order?: number;
  isActive?: boolean;
  target?: 'all' | 'device';
  deviceIds?: string[];
  startsAt?: string | null;
  endsAt?: string | null;
};

function isInRange(nowMs: number, startsAt?: string | null, endsAt?: string | null): boolean {
  if (startsAt) {
    const startMs = Date.parse(startsAt);
    if (!Number.isNaN(startMs) && nowMs < startMs) return false;
  }
  if (endsAt) {
    const endMs = Date.parse(endsAt);
    if (!Number.isNaN(endMs) && nowMs > endMs) return false;
  }
  return true;
}

function isTargetMatch(doc: PromotionDoc, deviceId: string): boolean {
  const target = doc.target ?? 'all';
  if (target === 'all') return true;
  const ids = Array.isArray(doc.deviceIds) ? doc.deviceIds : [];
  return ids.includes(deviceId);
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const deviceId = (url.searchParams.get('deviceId') || '').trim();
  if (!deviceId) {
    return NextResponse.json({ ok: false, error: 'missing_device_id' }, { status: 400 });
  }

  try {
    const db = getAdminDb();
    const snap = await db.collection('promotions').get();
    const nowMs = Date.now();
    const items = snap.docs
      .map((d) => ({ id: d.id, ...(d.data() as PromotionDoc) }))
      .filter((p) => p.isActive === true)
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

    const active = items.find((p) => isInRange(nowMs, p.startsAt, p.endsAt) && isTargetMatch(p, deviceId));
    if (!active) {
      return NextResponse.json({ ok: true, promotion: null });
    }
    return NextResponse.json({ ok: true, promotion: active });
  } catch (e) {
    return NextResponse.json({ ok: false, error: 'server_error', detail: String(e) }, { status: 500 });
  }
}

