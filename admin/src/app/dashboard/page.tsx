'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useAuth } from '@/contexts/AuthContext';
import Link from 'next/link';

function DashboardContent() {
  const { user, signOut } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold">Админ-панель</h1>
            </div>
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-600">
                {user?.username}
              </span>
              <button
                onClick={signOut}
                className="text-sm text-red-600 hover:text-red-700"
              >
                Выйти
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Link
            href="/categories"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Категории</h2>
            <p className="text-gray-600 text-sm">
              Управление категориями животных
            </p>
          </Link>

          <Link
            href="/categories"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Животные</h2>
            <p className="text-gray-600 text-sm">
              Выберите категорию и откройте животных
            </p>
          </Link>

          <Link
            href="/offers"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Офферы</h2>
            <p className="text-gray-600 text-sm">
              Управление специальными предложениями
            </p>
          </Link>

          <Link
            href="/analytics"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Аналитика</h2>
            <p className="text-gray-600 text-sm">
              Графики и статистика использования
            </p>
          </Link>

          <Link
            href="/parental-tests"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Родительский контроль</h2>
            <p className="text-gray-600 text-sm">
              Математические тесты для доступа к настройкам
            </p>
          </Link>

          <Link
            href="/promotions"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Скидки и акции</h2>
            <p className="text-gray-600 text-sm">
              Персональные и общие промо-баннеры в приложении
            </p>
          </Link>

          <Link
            href="/onboarding"
            className="bg-white p-6 rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-lg font-semibold mb-2">Онбординг</h2>
            <p className="text-gray-600 text-sm">
              Редактирование первых 3 экранов приложения
            </p>
          </Link>


        </div>
      </main>
    </div>
  );
}

export default function DashboardPage() {
  return (
    <ProtectedRoute>
      <DashboardContent />
    </ProtectedRoute>
  );
}
