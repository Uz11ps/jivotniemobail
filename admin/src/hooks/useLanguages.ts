import { useEffect, useState } from 'react';
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { AppLanguage, DEFAULT_LANGUAGES } from '@/lib/languages';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

/**
 * Live list of supported languages (admin-managed in Firestore `languages`
 * collection). Falls back to DEFAULT_LANGUAGES while loading or if Firestore
 * is unavailable.
 */
export function useLanguages() {
  const [languages, setLanguages] = useState<AppLanguage[]>(DEFAULT_LANGUAGES);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!db) {
      setLanguages(DEFAULT_LANGUAGES);
      setLoading(false);
      setError('Firestore недоступен, показан встроенный список языков.');
      return;
    }
    const q = query(collection(db, 'languages'), orderBy('order', 'asc'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        if (snap.empty) {
          setLanguages(DEFAULT_LANGUAGES);
        } else {
          setLanguages(
            snap.docs.map((d) => ({ code: d.id, ...(d.data() as Omit<AppLanguage, 'code'>) }))
          );
        }
        setLoading(false);
      },
      (err) => {
        console.error('languages snapshot:', err);
        setError(err.message);
        setLoading(false);
      }
    );
    return () => unsub();
  }, []);

  // CRUD via API routes (server-side, uses Admin SDK).
  const createLanguage = async (lang: AppLanguage) => {
    await tryServerWrite('/api/admin/languages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(lang),
    });
  };

  const updateLanguage = async (code: string, updates: Partial<AppLanguage>) => {
    await tryServerWrite(`/api/admin/languages/${code}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
  };

  const deleteLanguage = async (code: string) => {
    await tryServerWrite(`/api/admin/languages/${code}`, { method: 'DELETE' });
  };

  const reorderLanguages = async (newOrder: AppLanguage[]) => {
    await tryServerWrite('/api/admin/languages/reorder', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: newOrder.map((l, idx) => ({ code: l.code, order: idx })),
      }),
    });
  };

  /** Seed the 15 default languages if collection is empty. */
  const seedDefaults = async () => {
    await tryServerWrite('/api/admin/languages/seed', { method: 'POST' });
  };

  return {
    languages,
    loading,
    error,
    createLanguage,
    updateLanguage,
    deleteLanguage,
    reorderLanguages,
    seedDefaults,
  };
}
