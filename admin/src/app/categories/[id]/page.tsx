'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';

function CategoryDetailPage() {
  const params = useParams();
  const router = useRouter();
  const categoryId = params.id as string;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-6">
          <button onClick={() => router.push('/categories')} className="text-blue-600 mb-4">
            ← Назад к категориям
          </button>
          <h1 className="text-2xl font-bold">Управление животными</h1>
        </div>
        
        <Link
          href={`/categories/${categoryId}/animals`}
          className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
        >
          Перейти к животным →
        </Link>
      </div>
    </div>
  );
}

export default function CategoryDetail() {
  return (
    <ProtectedRoute>
      <CategoryDetailPage />
    </ProtectedRoute>
  );
}
