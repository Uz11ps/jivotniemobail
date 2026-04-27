// Поддерживаемые языки контента (имена, тексты, voice-аудио).
// Менять можно — порядок здесь = порядок отображения в формах.
// `code` должен быть ISO 639-1 (2 буквы), используется как ключ в Firestore.

export interface AppLanguage {
  code: string;       // ISO 639-1
  nameRu: string;     // подпись для админки
  flag: string;       // emoji флаг для UI
  required?: boolean; // если true — нельзя сохранить без перевода
}

export const SUPPORTED_LANGUAGES: AppLanguage[] = [
  { code: 'ru', nameRu: 'Русский',    flag: '🇷🇺', required: true },
  { code: 'en', nameRu: 'English',    flag: '🇬🇧', required: true },
  { code: 'es', nameRu: 'Español',    flag: '🇪🇸' },
  { code: 'pt', nameRu: 'Português',  flag: '🇵🇹' },
  { code: 'fr', nameRu: 'Français',   flag: '🇫🇷' },
  { code: 'de', nameRu: 'Deutsch',    flag: '🇩🇪' },
  { code: 'it', nameRu: 'Italiano',   flag: '🇮🇹' },
  { code: 'pl', nameRu: 'Polski',     flag: '🇵🇱' },
  { code: 'tr', nameRu: 'Türkçe',     flag: '🇹🇷' },
  { code: 'ar', nameRu: 'العربية',     flag: '🇦🇪' },
  { code: 'hi', nameRu: 'हिन्दी',      flag: '🇮🇳' },
  { code: 'zh', nameRu: '中文',        flag: '🇨🇳' },
  { code: 'ja', nameRu: '日本語',      flag: '🇯🇵' },
  { code: 'ko', nameRu: '한국어',       flag: '🇰🇷' },
  { code: 'uk', nameRu: 'Українська',  flag: '🇺🇦' },
];

export const LANGUAGE_CODES: string[] = SUPPORTED_LANGUAGES.map((l) => l.code);

export const REQUIRED_LANGUAGE_CODES: string[] = SUPPORTED_LANGUAGES
  .filter((l) => l.required)
  .map((l) => l.code);

export function getLanguage(code: string): AppLanguage | undefined {
  return SUPPORTED_LANGUAGES.find((l) => l.code === code);
}

/**
 * Read a value from a multi-language map with a sensible fallback chain:
 * desired lang → ru → en → first non-empty value → empty string.
 * Works with both new map-shape data and legacy `{ru,en}` objects.
 */
export function pickLocalized(
  map: Record<string, string | undefined> | null | undefined,
  lang: string,
  fallback = ''
): string {
  if (!map) return fallback;
  const direct = map[lang];
  if (direct && direct.length > 0) return direct;
  if (map.ru && map.ru.length > 0) return map.ru;
  if (map.en && map.en.length > 0) return map.en;
  for (const v of Object.values(map)) {
    if (typeof v === 'string' && v.length > 0) return v;
  }
  return fallback;
}

/**
 * Normalise legacy `{ru, en}` objects (or anything resembling) into a
 * full Record<lang, string> with empty strings for missing languages.
 * Safe to call on already-normalised data.
 */
export function normalizeLocalized(
  raw: Record<string, string | undefined> | null | undefined
): Record<string, string> {
  const out: Record<string, string> = {};
  for (const code of LANGUAGE_CODES) {
    out[code] = (raw && typeof raw[code] === 'string') ? (raw[code] as string) : '';
  }
  return out;
}
