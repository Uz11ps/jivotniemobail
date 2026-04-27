'use client';

import { useState } from 'react';
import { uploadFileWithMeta, getFileUrlFromPathOrUrl } from '@/lib/storage';
import { useLanguages } from '@/hooks/useLanguages';

interface MultiLangAudioUploadProps {
  label: string;
  /** Folder under Storage where files will land, e.g. `animals/voices/cat`. */
  basePath: string;
  /** Map: ISO code → Storage path (or legacy URL). */
  value: Record<string, string | undefined> | undefined;
  onChange: (next: Record<string, string>) => void;
}

/**
 * 15-language audio uploader. Tab switcher per language, with the ability
 * to bulk-upload a folder of files where each filename's prefix is the
 * language code (e.g. `ru.mp3`, `en.mp3`, `es.mp3`, …) — drops them all
 * into the right slots in one go.
 */
export function MultiLangAudioUpload({
  label,
  basePath,
  value,
  onChange,
}: MultiLangAudioUploadProps) {
  const { languages } = useLanguages();
  const [activeLang, setActiveLang] = useState<string>('ru');
  const [uploadingLang, setUploadingLang] = useState<string | null>(null);
  const [bulkProgress, setBulkProgress] = useState<{ done: number; total: number } | null>(null);

  const v = value ?? {};

  const setOne = (code: string, url: string) => {
    onChange({ ...(v as Record<string, string>), [code]: url });
  };

  const handleSingleUpload = async (
    code: string,
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingLang(code);
    try {
      const ext = file.name.split('.').pop() || 'mp3';
      const meta = await uploadFileWithMeta(`${basePath}/${code}-${Date.now()}.${ext}`, file);
      setOne(code, meta.url);
    } catch (err) {
      console.error(`Upload failed for ${code}:`, err);
      alert(`Не удалось загрузить аудио для ${code}: ${err instanceof Error ? err.message : err}`);
    } finally {
      setUploadingLang(null);
    }
  };

  const handleBulkUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const codeSet = new Set(languages.map((l) => l.code));
    const matched: Array<{ code: string; file: File }> = [];
    const skipped: string[] = [];

    for (const f of files) {
      // Filename heuristic: strip extension, then take the first 2-letter prefix
      // delimited by ., -, _, or space. e.g. "cat_ru.mp3", "ru-cat.mp3", "ru.mp3".
      const base = f.name.replace(/\.[^.]+$/, '');
      const tokens = base.split(/[._\-\s]+/);
      const found = tokens.find((t) => codeSet.has(t.toLowerCase()));
      if (found) {
        matched.push({ code: found.toLowerCase(), file: f });
      } else {
        skipped.push(f.name);
      }
    }

    if (matched.length === 0) {
      alert(
        'Не нашёл код языка в именах файлов. ' +
        'Назови файлы вида cat_ru.mp3 / cat_en.mp3 / ru.mp3 — двухбуквенный код должен быть отделён точкой, нижним подчёркиванием или дефисом.'
      );
      return;
    }

    setBulkProgress({ done: 0, total: matched.length });
    const next: Record<string, string> = { ...(v as Record<string, string>) };
    for (let i = 0; i < matched.length; i++) {
      const { code, file } = matched[i];
      try {
        const ext = file.name.split('.').pop() || 'mp3';
        const meta = await uploadFileWithMeta(`${basePath}/${code}-${Date.now()}.${ext}`, file);
        next[code] = meta.url;
        onChange(next);
      } catch (err) {
        console.error(`Bulk upload failed for ${code}:`, err);
      }
      setBulkProgress({ done: i + 1, total: matched.length });
    }
    setBulkProgress(null);

    if (skipped.length > 0) {
      alert(
        `Загружено ${matched.length} файлов. Пропущено ${skipped.length} (нет кода языка в имени):\n` +
        skipped.slice(0, 10).join('\n') +
        (skipped.length > 10 ? `\n…и ещё ${skipped.length - 10}` : '')
      );
    }
  };

  const filledCount = languages.filter((l) => v[l.code] && (v[l.code] as string).length > 0).length;
  const currentUrl = v[activeLang] ? getFileUrlFromPathOrUrl(v[activeLang] as string) : null;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4">
      <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
        <label className="text-sm font-semibold text-slate-700">{label}</label>
        <div className="flex items-center gap-3 text-xs text-slate-500">
          <span>{filledCount}/{languages.length} загружено</span>
          <label className="cursor-pointer rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs font-semibold text-slate-700 transition hover:bg-slate-100">
            ⬆ Массовая загрузка
            <input
              type="file"
              accept="audio/*"
              multiple
              className="hidden"
              onChange={handleBulkUpload}
            />
          </label>
        </div>
      </div>

      {bulkProgress && (
        <div className="mb-3 rounded-2xl border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-900">
          Загружено {bulkProgress.done}/{bulkProgress.total}…
        </div>
      )}

      <div className="mb-3 flex flex-wrap gap-1.5">
        {languages.map((lang) => {
          const filled = !!(v[lang.code] && (v[lang.code] as string).length > 0);
          const isActive = activeLang === lang.code;
          return (
            <button
              key={lang.code}
              type="button"
              onClick={() => setActiveLang(lang.code)}
              className={[
                'flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-semibold transition',
                isActive
                  ? 'border-slate-900 bg-slate-900 text-white'
                  : filled
                    ? 'border-emerald-200 bg-emerald-50 text-emerald-800 hover:bg-emerald-100'
                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50',
              ].join(' ')}
              title={lang.nameRu}
            >
              <span>{lang.flag}</span>
              <span className="uppercase">{lang.code}</span>
              {filled && <span className="text-emerald-600">✓</span>}
            </button>
          );
        })}
      </div>

      <div>
        <input
          type="file"
          accept="audio/*"
          onChange={(e) => handleSingleUpload(activeLang, e)}
          disabled={uploadingLang === activeLang}
          className="block w-full text-sm text-slate-500 file:mr-4 file:rounded-2xl file:border-0 file:bg-slate-900 file:px-4 file:py-2.5 file:text-sm file:font-semibold file:text-white hover:file:bg-slate-700"
        />
        {uploadingLang === activeLang && (
          <p className="mt-2 text-sm font-medium text-slate-500">Загрузка…</p>
        )}
        {currentUrl && (
          <div className="mt-3 rounded-2xl border border-slate-200 bg-slate-50 p-3">
            <audio src={currentUrl} controls className="w-full" />
            <button
              type="button"
              onClick={() => {
                const next = { ...(v as Record<string, string>) };
                delete next[activeLang];
                onChange(next);
              }}
              className="mt-2 text-xs font-semibold text-red-600 hover:text-red-800"
            >
              Удалить файл
            </button>
          </div>
        )}
      </div>

      <div className="mt-3 text-xs text-slate-400">
        💡 Для массовой загрузки 15 языков сразу — назови файлы как
        <code className="mx-1 rounded bg-slate-100 px-1 text-slate-700">cat_ru.mp3</code>,
        <code className="mx-1 rounded bg-slate-100 px-1 text-slate-700">cat_en.mp3</code>,
        … — двухбуквенный код языка должен встретиться в имени, отделённый
        точкой, дефисом или подчёркиванием.
      </div>
    </div>
  );
}
