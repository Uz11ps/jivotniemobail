'use client';

import { useState } from 'react';
import { useLanguages } from '@/hooks/useLanguages';

type Variant = 'text' | 'textarea';

interface MultiLangInputProps {
  label: string;
  /** Map of code → value. Missing entries treated as empty. */
  value: Record<string, string | undefined> | undefined;
  onChange: (next: Record<string, string>) => void;
  variant?: Variant;
  placeholder?: string;
  /** Show a compact "Перевод" button to copy ru/en into other empty langs. */
  showCopyTools?: boolean;
}

/**
 * Tabbed editor for a multi-language string. Languages with required:true
 * get red dot until filled. Other languages are optional.
 */
export function MultiLangInput({
  label,
  value,
  onChange,
  variant = 'text',
  placeholder = '',
  showCopyTools = true,
}: MultiLangInputProps) {
  const { languages } = useLanguages();
  const [activeLang, setActiveLang] = useState<string>('ru');
  const v = value ?? {};

  const setLang = (code: string, str: string) => {
    onChange({ ...(v as Record<string, string>), [code]: str });
  };

  const fillFromRu = () => {
    const src = v.ru || v.en || '';
    if (!src) return;
    const next: Record<string, string> = {};
    for (const lang of languages) {
      next[lang.code] = (v[lang.code] && (v[lang.code] as string).length > 0)
        ? (v[lang.code] as string)
        : src;
    }
    onChange(next);
  };

  const filledCount = languages.filter((l) => (v[l.code] && (v[l.code] as string).length > 0)).length;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4">
      <div className="mb-3 flex items-center justify-between gap-3">
        <label className="text-sm font-semibold text-slate-700">{label}</label>
        <div className="flex items-center gap-2 text-xs text-slate-500">
          <span>{filledCount}/{languages.length} заполнено</span>
          {showCopyTools && (
            <button
              type="button"
              onClick={fillFromRu}
              className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
              title="Заполнить пустые языки значением из RU/EN"
            >
              ↳ дополнить из RU
            </button>
          )}
        </div>
      </div>

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
                    : lang.required
                      ? 'border-red-200 bg-red-50 text-red-700 hover:bg-red-100'
                      : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50',
              ].join(' ')}
              title={lang.nameRu}
            >
              <span>{lang.flag}</span>
              <span className="uppercase">{lang.code}</span>
              {lang.required && !filled && <span aria-hidden>•</span>}
            </button>
          );
        })}
      </div>

      {languages.map((lang) => {
        if (lang.code !== activeLang) return null;
        const cur = (v[lang.code] as string) || '';
        const ph = placeholder ? `${placeholder} (${lang.nameRu})` : lang.nameRu;
        return (
          <div key={lang.code}>
            {variant === 'textarea' ? (
              <textarea
                rows={3}
                value={cur}
                onChange={(e) => setLang(lang.code, e.target.value)}
                placeholder={ph}
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              />
            ) : (
              <input
                type="text"
                value={cur}
                onChange={(e) => setLang(lang.code, e.target.value)}
                placeholder={ph}
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              />
            )}
            <div className="mt-1.5 text-xs text-slate-400">
              {lang.flag} {lang.nameRu}{lang.required ? ' · обязательный' : ' · опционально'}
            </div>
          </div>
        );
      })}
    </div>
  );
}
