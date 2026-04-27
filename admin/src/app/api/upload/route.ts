import { NextResponse } from 'next/server';
import Busboy from 'busboy';
import { createWriteStream } from 'node:fs';
import { mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { Readable } from 'node:stream';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const UPLOADS_ROOT = process.env.UPLOADS_DIR || '/var/www/deti-admin/uploads';

function sanitizeRelativePath(input: string): string {
  // normalize separators, remove leading slashes, prevent traversal
  const normalized = input.replace(/\\/g, '/').replace(/^\/+/, '');
  const safe = path.posix.normalize(normalized).replace(/^(\.\.(\/|\\|$))+/, '');
  return safe;
}

async function ensureDir(dirPath: string) {
  try {
    const s = await stat(dirPath);
    if (!s.isDirectory()) {
      throw new Error('Not a directory');
    }
  } catch (_) {
    await mkdir(dirPath, { recursive: true });
  }
}

export async function POST(req: Request) {
  const contentType = req.headers.get('content-type') || '';
  if (!contentType.toLowerCase().includes('multipart/form-data')) {
    return NextResponse.json({ error: 'Expected multipart/form-data' }, { status: 400 });
  }

  const url = new URL(req.url);
  const requestedPath = url.searchParams.get('path') || '';

  const headers: Record<string, string> = {};
  req.headers.forEach((v, k) => {
    headers[k] = v;
  });

  // Return only relative paths (e.g. /uploads/foo.mp3) — the browser will
  // resolve them against the current origin. Avoids two known issues:
  //  1) Some hosting providers add `X-Forwarded-Proto: https` even when
  //     HTTPS isn't terminated locally → we'd hand the browser broken URLs.
  //  2) Hardcoding 127.0.0.1:3000 when the API is hit directly from the box.
  await ensureDir(UPLOADS_ROOT);

  const bb = Busboy({ headers, limits: { files: 1 } });

  return await new Promise<Response>((resolve) => {
    let fileUrl: string | null = null;
    let relPublicPath: string | null = null;
    let hadFile = false;
    let writeDone: Promise<void> | null = null;

    bb.on('file', (_fieldname: string, file: any, info: any) => {
      hadFile = true;
      const { filename } = info;
      const ext = path.extname(filename || '').slice(0, 16);

      const baseRel = requestedPath
        ? sanitizeRelativePath(requestedPath)
        : `misc/${Date.now()}${ext || ''}`;

      const finalRel = baseRel || `misc/${Date.now()}${ext || ''}`;
      const diskPath = path.join(UPLOADS_ROOT, finalRel);
      const diskDir = path.dirname(diskPath);

      writeDone = ensureDir(diskDir).then(
        () =>
          new Promise<void>((res) => {
            const ws = createWriteStream(diskPath);
            file.pipe(ws);
            ws.on('finish', () => {
              relPublicPath = `/uploads/${finalRel.replace(/\\/g, '/')}`;
              fileUrl = relPublicPath;     // origin-relative — see comment above
              res();
            });
            ws.on('close', () => {
              if (!fileUrl || !relPublicPath) {
                relPublicPath = `/uploads/${finalRel.replace(/\\/g, '/')}`;
                fileUrl = relPublicPath;
              }
              res();
            });
            ws.on('error', () => res());
          }),
        () => {
          file.resume();
        }
      );
    });

    bb.on('finish', () => {
      (writeDone ?? Promise.resolve())
        .then(() => {
          if (!hadFile || !fileUrl || !relPublicPath) {
            resolve(NextResponse.json({ error: 'Upload failed' }, { status: 500 }));
            return;
          }
          resolve(
            NextResponse.json({
              url: fileUrl,
              publicPath: relPublicPath,
            })
          );
        })
        .catch(() => {
          resolve(NextResponse.json({ error: 'Upload failed' }, { status: 500 }));
        });
    });

    bb.on('error', () => {
      resolve(NextResponse.json({ error: 'Upload error' }, { status: 500 }));
    });

    // Convert Web stream to Node stream for Busboy.
    const body = req.body;
    if (!body) {
      resolve(NextResponse.json({ error: 'Empty body' }, { status: 400 }));
      return;
    }
    Readable.fromWeb(body as any).pipe(bb);
  });
}

