import { NextResponse } from 'next/server';
import { mkdir, readFile } from 'node:fs/promises';
import path from 'node:path';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type AnalyticsEvent = {
  type: 'category_open' | 'animal_open' | 'purchase';
  ts: number;
  categoryId?: string;
  animalId?: string;
  revenueRub?: number;
};

const ANALYTICS_DIR = process.env.ANALYTICS_DIR || '/var/www/deti-admin/analytics';
const EVENTS_FILE = 'events.jsonl';

function ymd(d: Date): string {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function safeParseJsonLines(text: string): AnalyticsEvent[] {
  const out: AnalyticsEvent[] = [];
  const lines = text.split('\n');
  for (const line of lines) {
    const t = line.trim();
    if (!t) continue;
    try {
      const j = JSON.parse(t) as AnalyticsEvent;
      if (j?.type && typeof j.ts === 'number') out.push(j);
    } catch {
      // ignore
    }
  }
  return out;
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const range = (url.searchParams.get('range') || 'week') as 'day' | 'week' | 'month';
  const days = range === 'day' ? 1 : range === 'month' ? 30 : 7;

  await mkdir(ANALYTICS_DIR, { recursive: true });
  const filePath = path.join(ANALYTICS_DIR, EVENTS_FILE);

  let events: AnalyticsEvent[] = [];
  try {
    const text = await readFile(filePath, 'utf8');
    events = safeParseJsonLines(text);
  } catch {
    events = [];
  }

  const end = new Date();
  end.setHours(23, 59, 59, 999);
  const start = new Date(end);
  start.setDate(end.getDate() - (days - 1));
  start.setHours(0, 0, 0, 0);

  const byDate: Record<
    string,
    {
      date: string;
      categoryOpens: number;
      animalOpens: number;
      revenueRub: number;
      topCategories: Record<string, number>;
      topAnimals: Record<string, number>;
    }
  > = {};

  // prefill days with zeros for nice charts
  for (let i = 0; i < days; i += 1) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const date = ymd(d);
    byDate[date] = {
      date,
      categoryOpens: 0,
      animalOpens: 0,
      revenueRub: 0,
      topCategories: {},
      topAnimals: {},
    };
  }

  for (const e of events) {
    const d = new Date(e.ts);
    if (d < start || d > end) continue;
    const date = ymd(d);
    const row = byDate[date] || (byDate[date] = {
      date,
      categoryOpens: 0,
      animalOpens: 0,
      revenueRub: 0,
      topCategories: {},
      topAnimals: {},
    });

    if (e.type === 'category_open') {
      row.categoryOpens += 1;
      if (e.categoryId) row.topCategories[e.categoryId] = (row.topCategories[e.categoryId] || 0) + 1;
    } else if (e.type === 'animal_open') {
      row.animalOpens += 1;
      if (e.animalId) row.topAnimals[e.animalId] = (row.topAnimals[e.animalId] || 0) + 1;
    } else if (e.type === 'purchase') {
      row.revenueRub += Number(e.revenueRub || 0);
    }
  }

  const series = Object.values(byDate).sort((a, b) => a.date.localeCompare(b.date));

  return NextResponse.json({ range, days, series });
}

