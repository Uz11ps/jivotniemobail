import { useEffect, useState } from 'react';
import { Promotion } from '@/types';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

export function usePromotions() {
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    try {
      const res = await fetch('/api/admin/promotions', { method: 'GET' });
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        throw new Error(text || `HTTP ${res.status}`);
      }
      const json = (await res.json()) as { items?: Promotion[] };
      setPromotions(json.items ?? []);
    } catch (error) {
      console.error('Ошибка загрузки акций:', error);
      setPromotions([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void refresh();
    const timer = window.setInterval(() => {
      void refresh();
    }, 3000);
    return () => window.clearInterval(timer);
  }, []);

  const createPromotion = async (promotion: Omit<Promotion, 'id'>) => {
    const json = await tryServerWrite('/api/admin/promotions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(promotion),
    });
    await refresh();
    return (json as any).id as string;
  };

  const updatePromotion = async (id: string, updates: Partial<Promotion>) => {
    await tryServerWrite(`/api/admin/promotions/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    await refresh();
  };

  const deletePromotion = async (id: string) => {
    await tryServerWrite(`/api/admin/promotions/${id}`, { method: 'DELETE' });
    await refresh();
  };

  return {
    promotions,
    loading,
    createPromotion,
    updatePromotion,
    deletePromotion,
  };
}

