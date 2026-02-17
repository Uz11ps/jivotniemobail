import crypto from 'node:crypto';

export const ADMIN_SESSION_COOKIE = 'deti_admin_session';

const DEFAULT_USERNAME = '123';
const DEFAULT_PASSWORD = '123';

function getSecret(): string {
  // Для продакшена лучше задать переменную окружения.
  return process.env.ADMIN_SESSION_SECRET || 'deti-admin-session-secret';
}

export function validateCredentials(username: string, password: string): boolean {
  const expectedUser = process.env.ADMIN_USERNAME || DEFAULT_USERNAME;
  const expectedPass = process.env.ADMIN_PASSWORD || DEFAULT_PASSWORD;
  return username === expectedUser && password === expectedPass;
}

type SessionPayload = {
  u: string;
  iat: number;
  exp: number;
};

function sign(payloadB64: string): string {
  return crypto.createHmac('sha256', getSecret()).update(payloadB64).digest('hex');
}

export function createSessionCookieValue(username: string): string {
  const now = Date.now();
  const payload: SessionPayload = {
    u: username,
    iat: now,
    exp: now + 1000 * 60 * 60 * 24 * 30, // 30 дней
  };
  const payloadB64 = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
  const sig = sign(payloadB64);
  return `${payloadB64}.${sig}`;
}

export function verifySessionCookieValue(value: string | undefined | null): SessionPayload | null {
  if (!value) return null;
  const parts = value.split('.');
  if (parts.length !== 2) return null;
  const [payloadB64, sig] = parts;
  if (!payloadB64 || !sig) return null;

  const expected = sign(payloadB64);
  try {
    const a = Buffer.from(sig, 'hex');
    const b = Buffer.from(expected, 'hex');
    if (a.length !== b.length) return null;
    if (!crypto.timingSafeEqual(a, b)) return null;
  } catch {
    return null;
  }

  try {
    const payload = JSON.parse(Buffer.from(payloadB64, 'base64url').toString('utf8')) as SessionPayload;
    if (!payload?.u || !payload.exp) return null;
    if (Date.now() > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

