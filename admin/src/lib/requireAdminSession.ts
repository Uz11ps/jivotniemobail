import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { ADMIN_SESSION_COOKIE, verifySessionCookieValue } from '@/lib/adminAuth';

export async function requireAdminSession(): Promise<NextResponse | null> {
  const jar = await cookies();
  const raw = jar.get(ADMIN_SESSION_COOKIE)?.value;
  const payload = verifySessionCookieValue(raw);
  if (!payload) {
    return NextResponse.json({ ok: false, error: 'unauthorized' }, { status: 401 });
  }
  return null;
}

