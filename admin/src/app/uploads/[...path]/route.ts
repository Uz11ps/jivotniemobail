import { NextResponse } from 'next/server';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import { Readable } from 'node:stream';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const UPLOADS_ROOT = process.env.UPLOADS_DIR || '/var/www/deti-admin/uploads';

function sanitizeRelativePath(input: string): string {
  const normalized = input.replace(/\\/g, '/').replace(/^\/+/, '');
  return path.posix.normalize(normalized).replace(/^(\.\.(\/|\\|$))+/, '');
}

function guessContentType(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.mp4':
      return 'video/mp4';
    case '.webm':
      return 'video/webm';
    case '.mov':
      return 'video/quicktime';
    case '.mp3':
      return 'audio/mpeg';
    case '.wav':
      return 'audio/wav';
    case '.m4a':
      return 'audio/mp4';
    case '.aac':
      return 'audio/aac';
    case '.ogg':
      return 'audio/ogg';
    case '.json':
      return 'application/json';
    default:
      return 'application/octet-stream';
  }
}

export async function GET(req: Request, ctx: { params: Promise<{ path: string[] }> }) {
  const params = await ctx.params;
  const rel = sanitizeRelativePath((params.path || []).join('/'));

  const rootAbs = path.resolve(UPLOADS_ROOT);
  const fileAbs = path.resolve(rootAbs, rel);
  if (!fileAbs.startsWith(rootAbs + path.sep) && fileAbs !== rootAbs) {
    return NextResponse.json({ error: 'Invalid path' }, { status: 400 });
  }

  let s;
  try {
    s = await stat(fileAbs);
  } catch {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
  if (!s.isFile()) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  const totalSize = s.size;
  const range = req.headers.get('range');
  const contentType = guessContentType(fileAbs);

  const commonHeaders: Record<string, string> = {
    'Content-Type': contentType,
    'Accept-Ranges': 'bytes',
    // Для админки/мобилки файлы могут часто обновляться; кэш делаем умеренный.
    'Cache-Control': 'public, max-age=3600',
  };

  if (range) {
    const m = /^bytes=(\d+)-(\d+)?$/.exec(range.trim());
    if (!m) {
      return new Response(null, { status: 416, headers: commonHeaders });
    }
    const start = Number(m[1]);
    const end = m[2] ? Number(m[2]) : totalSize - 1;
    if (Number.isNaN(start) || Number.isNaN(end) || start > end || start >= totalSize) {
      return new Response(null, { status: 416, headers: commonHeaders });
    }

    const chunkSize = end - start + 1;
    const stream = createReadStream(fileAbs, { start, end });
    return new Response(Readable.toWeb(stream) as any, {
      status: 206,
      headers: {
        ...commonHeaders,
        'Content-Range': `bytes ${start}-${end}/${totalSize}`,
        'Content-Length': String(chunkSize),
      },
    });
  }

  const stream = createReadStream(fileAbs);
  return new Response(Readable.toWeb(stream) as any, {
    status: 200,
    headers: {
      ...commonHeaders,
      'Content-Length': String(totalSize),
    },
  });
}

