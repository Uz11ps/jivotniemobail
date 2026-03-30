import { useState, useEffect } from 'react';
import { 
  collection,
  query,
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { Animal } from '@/types';
import { getDefaultAnimals, mergeAnimalsWithDefaults } from '@/lib/catalogDefaults';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

export function useAnimals(categoryId: string) {
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!categoryId) return;
    if (!db) {
      setAnimals(getDefaultAnimals(categoryId));
      setLoading(false);
      setError('Firestore недоступен, показаны встроенные животные.');
      return;
    }
    const firestore = db;
    const q = query(
      collection(firestore, 'categories', categoryId, 'animals'),
      orderBy('order', 'asc')
    );
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() })) as Animal[];
        setAnimals(mergeAnimalsWithDefaults(categoryId, data));
        setLoading(false);
        setError(null);
      },
      (error) => {
        console.error('Ошибка загрузки животных:', error);
        setAnimals(getDefaultAnimals(categoryId));
        setLoading(false);
        setError(`Не удалось загрузить Firestore. Показаны встроенные животные. ${String(error?.message || error)}`);
      }
    );
    return () => unsub();
  }, [categoryId]);

  const loadAnimals = async () => {
    if (!categoryId) return;
    if (!db) {
      setAnimals(getDefaultAnimals(categoryId));
      setLoading(false);
      return;
    }
    const firestore = db;
    
    try {
      // realtime идет через onSnapshot, оставляем refresh для совместимости
      void firestore;
    } catch (error) {
      console.error('Ошибка загрузки животных:', error);
    } finally {
      setLoading(false);
    }
  };

  const createAnimal = async (animal: Omit<Animal, 'id'>) => {
    if (!categoryId) throw new Error('Category ID required');
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    
    try {
      const json = await tryServerWrite(`/api/admin/categories/${categoryId}/animals`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(animal),
      });
      return (json as any).id as string;
    } catch (error) {
      console.error('Ошибка создания животного:', error);
      throw error;
    }
  };

  const updateAnimal = async (id: string, updates: Partial<Animal>) => {
    if (!categoryId) throw new Error('Category ID required');
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    
    try {
      await tryServerWrite(`/api/admin/categories/${categoryId}/animals/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
    } catch (error) {
      console.error('Ошибка обновления животного:', error);
      throw error;
    }
  };

  const deleteAnimal = async (id: string) => {
    if (!categoryId) throw new Error('Category ID required');
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    
    try {
      await tryServerWrite(`/api/admin/categories/${categoryId}/animals/${id}`, { method: 'DELETE' });
    } catch (error) {
      console.error('Ошибка удаления животного:', error);
      throw error;
    }
  };

  const reorderAnimals = async (newOrder: Animal[]) => {
    if (!categoryId) throw new Error('Category ID required');
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    
    try {
      const optimistic = newOrder.map((a, idx) => ({ ...a, order: idx }));
      setAnimals(optimistic);
      const ids = newOrder.map((a) => a.id).filter(Boolean) as string[];
      await tryServerWrite(`/api/admin/categories/${categoryId}/animals/reorder`, {
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
    animals,
    loading,
    error,
    createAnimal,
    updateAnimal,
    deleteAnimal,
    reorderAnimals,
    refresh: loadAnimals
  };
}
