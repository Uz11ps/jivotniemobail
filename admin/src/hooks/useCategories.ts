import { useState, useEffect } from 'react';
import { 
  collection,
  query,
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { Category } from '@/types';
import { defaultCategories, mergeCategoriesWithDefaults } from '@/lib/catalogDefaults';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

export function useCategories() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!db) {
      setCategories(defaultCategories);
      setLoading(false);
      setError('Firestore недоступен, показан встроенный каталог.');
      return;
    }
    const firestore = db;
    const q = query(collection(firestore, 'categories'), orderBy('order', 'asc'));
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() })) as Category[];
        setCategories(mergeCategoriesWithDefaults(data));
        setLoading(false);
        setError(null);
      },
      (error) => {
        console.error('Ошибка загрузки категорий:', error);
        setCategories(defaultCategories);
        setLoading(false);
        setError(`Не удалось загрузить Firestore. Показан встроенный каталог. ${String(error?.message || error)}`);
      }
    );
    return () => unsub();
  }, []);

  const loadCategories = async () => {
    if (!db) {
      setCategories([]);
      setLoading(false);
      return;
    }
    const firestore = db;
    try {
      // realtime идет через onSnapshot, оставляем refresh для совместимости
      void firestore;
    } catch (error) {
      console.error('Ошибка загрузки категорий:', error);
    } finally {
      setLoading(false);
    }
  };

  const createCategory = async (category: Omit<Category, 'id'>) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      const json = await tryServerWrite('/api/admin/categories', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(category),
      });
      return (json as any).id as string;
    } catch (error) {
      console.error('Ошибка создания категории:', error);
      throw error;
    }
  };

  const updateCategory = async (id: string, updates: Partial<Category>) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      await tryServerWrite(`/api/admin/categories/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
    } catch (error) {
      console.error('Ошибка обновления категории:', error);
      throw error;
    }
  };

  const deleteCategory = async (id: string) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      await tryServerWrite(`/api/admin/categories/${id}`, { method: 'DELETE' });
    } catch (error) {
      console.error('Ошибка удаления категории:', error);
      throw error;
    }
  };

  const reorderCategories = async (newOrder: Category[]) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      // Оптимистично обновляем UI сразу (иначе dnd "откатывается" и кажется что не работает)
      const optimistic = newOrder.map((c, idx) => ({ ...c, order: idx }));
      setCategories(optimistic);

      const ids = newOrder.map((c) => c.id).filter(Boolean) as string[];
      await tryServerWrite('/api/admin/categories/reorder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ids }),
      });
    } catch (error) {
      console.error('Ошибка изменения порядка:', error);
      throw error;
    }
  };

  return {
    categories,
    loading,
    error,
    createCategory,
    updateCategory,
    deleteCategory,
    reorderCategories,
    refresh: loadCategories
  };
}
