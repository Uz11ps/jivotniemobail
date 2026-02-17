'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';

function UsersContent() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-2xl font-bold mb-6">Пользователи</h1>
        <div className="bg-white rounded-lg shadow p-6 text-gray-700">
          Роли/управление пользователями отключены. Админка защищена логином/паролем `123/123`.
        </div>
      </div>
    </div>
  );
}

export default function UsersPage() {
  return (
    <ProtectedRoute>
      <UsersContent />
    </ProtectedRoute>
  );
}
