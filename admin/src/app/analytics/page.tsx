'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useState, useEffect } from 'react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface AnalyticsDailyDoc {
  date: string; // YYYY-MM-DD
  categoryOpens: number;
  animalOpens: number;
  revenueRub: number;
  topCategories?: Record<string, number>;
  topAnimals?: Record<string, number>;
}

function AnalyticsContent() {
  const [data, setData] = useState<AnalyticsDailyDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState<'day' | 'week' | 'month'>('week');

  useEffect(() => {
    let cancelled = false;
    let timer: any = null;

    const load = async () => {
      try {
        setLoading(true);
        const res = await fetch(`/api/analytics/summary?range=${timeRange}`, { cache: 'no-store' });
        const json = (await res.json()) as { series?: AnalyticsDailyDoc[] };
        if (cancelled) return;
        setData(Array.isArray(json.series) ? json.series : []);
      } catch (e) {
        console.error('Ошибка загрузки аналитики:', e);
        if (!cancelled) setData([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    load();
    // лёгкий "realtime": обновляем раз в 5 секунд
    timer = setInterval(load, 5000);

    return () => {
      cancelled = true;
      if (timer) clearInterval(timer);
    };
  }, [timeRange]);

  const totals = data.reduce(
    (acc, d) => {
      acc.categoryOpens += d.categoryOpens || 0;
      acc.animalOpens += d.animalOpens || 0;
      acc.revenueRub += d.revenueRub || 0;
      return acc;
    },
    { categoryOpens: 0, animalOpens: 0, revenueRub: 0 }
  );

  const topCategories = (() => {
    const map: Record<string, number> = {};
    for (const d of data) {
      const tc = d.topCategories || {};
      for (const [k, v] of Object.entries(tc)) map[k] = (map[k] || 0) + (v || 0);
    }
    return Object.entries(map)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 10);
  })();

  const topAnimals = (() => {
    const map: Record<string, number> = {};
    for (const d of data) {
      const ta = d.topAnimals || {};
      for (const [k, v] of Object.entries(ta)) map[k] = (map[k] || 0) + (v || 0);
    }
    return Object.entries(map)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 10);
  })();

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Аналитика</h1>
          <div className="flex gap-2">
            <button
              onClick={() => setTimeRange('day')}
              className={`px-4 py-2 rounded ${timeRange === 'day' ? 'bg-blue-600 text-white' : 'bg-white'}`}
            >
              День
            </button>
            <button
              onClick={() => setTimeRange('week')}
              className={`px-4 py-2 rounded ${timeRange === 'week' ? 'bg-blue-600 text-white' : 'bg-white'}`}
            >
              Неделя
            </button>
            <button
              onClick={() => setTimeRange('month')}
              className={`px-4 py-2 rounded ${timeRange === 'month' ? 'bg-blue-600 text-white' : 'bg-white'}`}
            >
              Месяц
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Открытия категорий</h2>
            {data.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="categoryOpens" name="Открытия" stroke="#8884d8" />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-300 flex items-center justify-center text-gray-500">
                Нет реальных данных за выбранный период (события еще не приходили)
              </div>
            )}
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Открытия животных</h2>
            {data.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="animalOpens" name="Открытия" stroke="#82ca9d" />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-300 flex items-center justify-center text-gray-500">
                Нет реальных данных за выбранный период (события еще не приходили)
              </div>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Топ категорий</h2>
            {topCategories.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={topCategories}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="value" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-300 flex items-center justify-center text-gray-500">
                Нет данных
              </div>
            )}
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Топ животных</h2>
            {topAnimals.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={topAnimals}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="value" fill="#82ca9d" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-300 flex items-center justify-center text-gray-500">
                Нет данных
              </div>
            )}
          </div>
        </div>

        <div className="mt-6 bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Доходы</h2>
          {data.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="revenueRub" name="₽" stroke="#ffc658" />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-300 flex items-center justify-center text-gray-500">
              Нет реальных данных за выбранный период (события еще не приходили)
            </div>
          )}
        </div>

        <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-sm text-gray-500">Открытия категорий</div>
            <div className="text-2xl font-bold">{totals.categoryOpens}</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-sm text-gray-500">Открытия животных</div>
            <div className="text-2xl font-bold">{totals.animalOpens}</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-sm text-gray-500">Доход (₽)</div>
            <div className="text-2xl font-bold">{totals.revenueRub}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function AnalyticsPage() {
  return (
    <ProtectedRoute>
      <AnalyticsContent />
    </ProtectedRoute>
  );
}
