import { NextResponse } from 'next/server';
import { mkdir, appendFile } from 'node:fs/promises';
import path from 'node:path';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type AnalyticsEvent = {
  type: 'category_open' | 'animal_open' | 'purchase';
  ts?: number; // client ts (optional)
  categoryId?: string;
  animalId?: string;
  revenueRub?: number;
};

const ANALYTICS_DIR = process.env.ANALYTICS_DIR || '/var/www/deti-admin/analytics';
const EVENTS_FILE = 'events.jsonl';

function getKey(): string {
  return process.env.ANALYTICS_INGEST_KEY || 'analytics123';
}

export async function POST(req: Request) {
  const key = req.headers.get('x-analytics-key') || '';
  if (!key || key !== getKey()) {
    return NextResponse.json({ ok: false, error: 'unauthorized' }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as AnalyticsEvent | null;
  if (!body?.type) {
    return NextResponse.json({ ok: false, error: 'bad_request' }, { status: 400 });
  }

  const serverTs = Date.now();
  const event = {
    ...body,
    ts: typeof body.ts === 'number' ? body.ts : serverTs,
    serverTs,
  };

  await mkdir(ANALYTICS_DIR, { recursive: true });
  const filePath = path.join(ANALYTICS_DIR, EVENTS_FILE);
  await appendFile(filePath, JSON.stringify(event) + '\n', 'utf8');

  return NextResponse.json({ ok: true });
}

