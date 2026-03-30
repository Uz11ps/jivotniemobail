'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { AdminShell } from '@/components/AdminShell';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';

function CategoryDetailPage() {
  const params = useParams();
  const router = useRouter();
  const categoryId = params.id as string;

  return (
    <AdminShell
      title="Раздел категории"
      subtitle="Отсюда можно перейти к полному списку животных выбранной категории."
    >
      <div className="rounded-[28px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-6">
        <button
          onClick={() => router.push('/categories')}
          className="mb-4 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
        >
          ← Назад к категориям
        </button>
        <h2 className="text-2xl font-black tracking-tight text-slate-900">Управление животными</h2>
        <p className="mt-2 text-sm text-slate-500">
          Категория: <span className="font-semibold text-slate-800">{categoryId}</span>
        </p>

        <Link
          href={`/categories/${categoryId}/animals`}
          className="mt-6 inline-flex rounded-2xl bg-slate-900 px-6 py-3 text-sm font-bold text-white transition hover:bg-slate-700"
        >
          Перейти к животным →
        </Link>
      </div>
    </AdminShell>
  );
}

export default function CategoryDetail() {
  return (
    <ProtectedRoute>
      <CategoryDetailPage />
    </ProtectedRoute>
  );
}
