import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import {
  ADMIN_SESSION_COOKIE,
  createSessionCookieValue,
  validateCredentials,
} from '@/lib/adminAuth';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as
    | { username?: string; password?: string; login?: string }
    | null;

  const username = (body?.username || body?.login || '').trim();
  const password = (body?.password || '').trim();

  if (!validateCredentials(username, password)) {
    return NextResponse.json({ ok: false, error: 'invalid_credentials' }, { status: 401 });
  }

  const cookieValue = createSessionCookieValue(username);
  const forcedSecure = process.env.ADMIN_COOKIE_SECURE;
  const proto = req.headers.get('x-forwarded-proto') || new URL(req.url).protocol.replace(':', '');
  const isHttps = proto === 'https';
  const isProd = process.env.NODE_ENV === 'production';
  // Если явно задано в env — берем его. Иначе в проде включаем secure только при https.
  const secureCookie = typeof forcedSecure === 'string'
    ? forcedSecure === 'true'
    : (isProd && isHttps);

  const jar = await cookies();
  jar.set(ADMIN_SESSION_COOKIE, cookieValue, {
    httpOnly: true,
    sameSite: 'lax',
    secure: secureCookie,
    path: '/',
    maxAge: 60 * 60 * 24 * 30,
  });

  return NextResponse.json({ ok: true, user: { username } });
}

