// В этом проекте Firebase Storage не используем (он платный на твоём тарифе).
// Файлы загружаем на сервер через Next API (/api/upload) и храним URL в Firestore.

export async function uploadFile(
  path: string,
  file: File
): Promise<string> {
  const meta = await uploadFileWithMeta(path, file);
  return meta.url;
}

export async function uploadFileWithMeta(
  path: string,
  file: File
): Promise<{ path: string; url: string }> {
  const formData = new FormData();
  formData.append('file', file);

  const res = await fetch(`/api/upload?path=${encodeURIComponent(path)}`, {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) {
    throw new Error(`Upload failed: ${res.status}`);
  }
  const json = (await res.json()) as { url?: string; publicPath?: string };
  if (!json.url || !json.publicPath) {
    throw new Error('Upload failed: invalid response');
  }
  // Возвращаем и url, и public path (на всякий случай).
  return { path: json.publicPath, url: json.url };
}

export async function deleteFile(path: string): Promise<void> {
  // Опционально: можно добавить /api/delete позже
  void path;
}

export function getFileUrl(path: string): string {
  // Если хранится /uploads/.. или полный URL — используем как есть
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('/')) return path;
  return `/uploads/${path}`;
}

// Поддержка legacy: если в Firestore лежит абсолютный URL — пробуем извлечь
// /uploads/... и сделать относительный путь, чтобы браузер сам подобрал
// правильный scheme/host. Это лечит старые записи, где сервер вернул
// https://… (а на проде https-а нет) или http://127.0.0.1:3000/...
export function getFileUrlFromPathOrUrl(value: string): string {
  if (!value) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    try {
      const u = new URL(value);
      if (u.pathname.startsWith('/uploads/')) return u.pathname + u.search;
    } catch {
      /* not a valid URL, return as-is */
    }
    return value;
  }
  return getFileUrl(value);
}
