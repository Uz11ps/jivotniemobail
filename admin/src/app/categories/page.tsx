'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useCategories } from '@/hooks/useCategories';
import { SortableList } from '@/components/SortableList';
import { Category } from '@/types';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { StorageFileUpload } from '@/components/StorageFileUpload';
import { getFileUrlFromPathOrUrl } from '@/lib/storage';
import { useRouter } from 'next/navigation';

const categorySchema = z.object({
  order: z.number(),
  isVisible: z.boolean(),
  isPaid: z.boolean(),
  iapProductId: z.string().nullable().optional(),
  priceRub: z.number().nullable().optional(),
  title: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  // Разрешаем пустое значение, чтобы можно было засеять Firestore и заполнять медиа постепенно.
  tabIconAssetPath: z.string().optional(),
});

function CategoriesContent() {
  const { categories, loading, error, createCategory, updateCategory, deleteCategory, reorderCategories } = useCategories();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const router = useRouter();

  const { register, handleSubmit, reset, setValue, watch, formState: { errors } } = useForm<Category>({
    resolver: zodResolver(categorySchema),
    defaultValues: {
      order: categories.length,
      isVisible: true,
      isPaid: false,
      priceRub: null,
      title: { ru: '', en: '' },
      tabIconAssetPath: '',
    },
  });

  const onSubmit = async (data: Category) => {
    try {
      const payload: Category = {
        ...data,
        tabIconAssetPath: data.tabIconAssetPath || '',
      };
      if (editingId) {
        await updateCategory(editingId, payload);
        setEditingId(null);
      } else {
        await createCategory(payload);
        setShowForm(false);
      }
      reset();
    } catch (error) {
      console.error('Ошибка сохранения:', error);
    }
  };

  const handleReorder = async (newOrder: Category[]) => {
    await reorderCategories(newOrder);
  };

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {error && (
          <div className="mb-4 rounded-lg bg-red-50 border border-red-200 p-3 text-sm text-red-900">
            Ошибка загрузки категорий: {error}
          </div>
        )}
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Категории</h1>
          <button
            onClick={() => {
              setShowForm(true);
              setEditingId(null);
              reset({
                order: categories.length,
                isVisible: true,
                isPaid: false,
                priceRub: null,
                title: { ru: '', en: '' },
                tabIconAssetPath: '',
              });
            }}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Добавить категорию
          </button>
        </div>

        {(showForm || editingId) && (
          <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">
              {editingId ? 'Редактировать категорию' : 'Новая категория'}
            </h2>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Название (RU)</label>
                <input {...register('title.ru')} className="w-full border rounded px-3 py-2" />
                {errors.title?.ru && <p className="text-red-500 text-sm">{errors.title.ru.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Название (EN)</label>
                <input {...register('title.en')} className="w-full border rounded px-3 py-2" />
                {errors.title?.en && <p className="text-red-500 text-sm">{errors.title.en.message}</p>}
              </div>
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`categories/icons/${Date.now()}.png`}
                value={watch('tabIconAssetPath')}
                onUploaded={(meta) => setValue('tabIconAssetPath', meta.url)}
                accept="image/*"
                label="Иконка для таба"
              />
              {watch('tabIconAssetPath') && (
                <img
                  src={getFileUrlFromPathOrUrl(watch('tabIconAssetPath'))}
                  alt="Icon"
                  className="w-16 h-16 mt-2 rounded"
                />
              )}
            </div>

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isPaid')} />
                <span>Платная категория</span>
              </label>
            </div>

            {watch('isPaid') && (
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Product ID (StoreKit)</label>
                  <input
                    {...register('iapProductId')}
                    className="w-full border rounded px-3 py-2"
                    placeholder="com.app.category_id"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Цена (₽)</label>
                  <input
                    type="number"
                    step="1"
                    {...register('priceRub', { valueAsNumber: true })}
                    className="w-full border rounded px-3 py-2"
                    placeholder="69"
                  />
                </div>
              </div>
            )}

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isVisible')} />
                <span>Видима</span>
              </label>
            </div>

            <div className="flex gap-2">
              <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
                Сохранить
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowForm(false);
                  setEditingId(null);
                  reset();
                }}
                className="bg-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-400"
              >
                Отмена
              </button>
            </div>
          </form>
        )}

        <div className="bg-white rounded-lg shadow overflow-hidden">
          <SortableList
            items={categories}
            onReorder={handleReorder}
            renderItem={(category) => (
              <div className="flex items-center justify-between p-4 border-b">
                <div className="flex items-center gap-4">
                  <span className="font-semibold">{category.title.ru}</span>
                  {category.isPaid && (
                    <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">
                      Платная
                    </span>
                  )}
                  {!category.isVisible && (
                    <span className="bg-gray-100 text-gray-800 text-xs px-2 py-1 rounded">
                      Скрыта
                    </span>
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => router.push(`/categories/${category.id}/animals`)}
                    className="text-gray-700 hover:text-gray-900"
                  >
                    Животные
                  </button>
                  <button
                    onClick={() => {
                      setEditingId(category.id!);
                      setShowForm(true);
                      reset(category);
                    }}
                    className="text-blue-600 hover:text-blue-800"
                  >
                    Редактировать
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('Удалить категорию?')) {
                        deleteCategory(category.id!);
                      }
                    }}
                    className="text-red-600 hover:text-red-800"
                  >
                    Удалить
                  </button>
                </div>
              </div>
            )}
          />
        </div>
      </div>
    </div>
  );
}

export default function CategoriesPage() {
  return (
    <ProtectedRoute>
      <CategoriesContent />
    </ProtectedRoute>
  );
}
