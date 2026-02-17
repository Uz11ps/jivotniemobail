import { useState, useEffect } from 'react';
import { 
  collection,
  query,
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { Offer } from '@/types';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

export function useOffers() {
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!db) {
      setOffers([]);
      setLoading(false);
      return;
    }
    const firestore = db;
    const q = query(collection(firestore, 'offers'), orderBy('title.ru', 'asc'));
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() })) as Offer[];
        setOffers(data);
        setLoading(false);
      },
      (error) => {
        console.error('Ошибка загрузки офферов:', error);
        setLoading(false);
      }
    );
    return () => unsub();
  }, []);

  const loadOffers = async () => {
    if (!db) {
      setOffers([]);
      setLoading(false);
      return;
    }
    const firestore = db;
    try {
      // realtime идет через onSnapshot, оставляем refresh для совместимости
      void firestore;
    } catch (error) {
      console.error('Ошибка загрузки офферов:', error);
    } finally {
      setLoading(false);
    }
  };

  const createOffer = async (offer: Omit<Offer, 'id'>) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      const json = await tryServerWrite('/api/admin/offers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(offer),
      });
      return (json as any).id as string;
    } catch (error) {
      console.error('Ошибка создания оффера:', error);
      throw error;
    }
  };

  const updateOffer = async (id: string, updates: Partial<Offer>) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      await tryServerWrite(`/api/admin/offers/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
    } catch (error) {
      console.error('Ошибка обновления оффера:', error);
      throw error;
    }
  };

  const deleteOffer = async (id: string) => {
    if (!db) {
      throw new Error('Firestore не инициализирован');
    }
    try {
      await tryServerWrite(`/api/admin/offers/${id}`, { method: 'DELETE' });
    } catch (error) {
      console.error('Ошибка удаления оффера:', error);
      throw error;
    }
  };

  return {
    offers,
    loading,
    createOffer,
    updateOffer,
    deleteOffer,
    refresh: loadOffers
  };
}
