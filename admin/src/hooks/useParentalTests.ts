import { useEffect, useState } from 'react';
import { ParentalTest } from '@/types';

async function tryServerWrite(path: string, init: RequestInit) {
  const res = await fetch(path, init);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json().catch(() => ({}));
}

export function useParentalTests() {
  const [tests, setTests] = useState<ParentalTest[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    try {
      const res = await fetch('/api/admin/parental-tests', { method: 'GET' });
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        throw new Error(text || `HTTP ${res.status}`);
      }
      const json = (await res.json()) as { items?: ParentalTest[] };
      setTests(json.items ?? []);
    } catch (error) {
      console.error('Ошибка загрузки тестов родительского контроля:', error);
      setTests([]);
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

  const createTest = async (test: Omit<ParentalTest, 'id'>) => {
    const json = await tryServerWrite('/api/admin/parental-tests', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(test),
    });
    await refresh();
    return (json as any).id as string;
  };

  const updateTest = async (id: string, updates: Partial<ParentalTest>) => {
    await tryServerWrite(`/api/admin/parental-tests/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    await refresh();
  };

  const deleteTest = async (id: string) => {
    await tryServerWrite(`/api/admin/parental-tests/${id}`, { method: 'DELETE' });
    await refresh();
  };

  return {
    tests,
    loading,
    createTest,
    updateTest,
    deleteTest,
  };
}

