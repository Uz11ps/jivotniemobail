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
import { MultiLangInput } from '@/components/MultiLangInput';
import { getFileUrlFromPathOrUrl } from '@/lib/storage';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { pickLocalized } from '@/lib/languages';

const categorySchema = z.object({
  order: z.number(),
  isVisible: z.boolean(),
  isPaid: z.boolean(),
  iapProductId: z.string().nullable().optional(),
  priceRub: z.number().nullable().optional(),
  title: z.record(z.string()).refine((v) => !!v.ru && v.ru.length > 0, {
    message: 'RU обязателен',
  }),
  // Разрешаем пустое значение, чтобы можно было засеять Firestore и заполнять медиа постепенно.
  tabIconAssetPath: z.string().optional(),
  heroImageAssetPath: z.string().optional(),
  heroVideoAssetPath: z.string().optional(),
  backgroundColorHex: z.string().optional(),
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
      heroImageAssetPath: '',
      heroVideoAssetPath: '',
      backgroundColorHex: '#66AEF8',
    },
  });

  const onSubmit = async (data: Category) => {
    try {
      const payload: Category = {
        ...data,
        tabIconAssetPath: data.tabIconAssetPath || '',
        heroImageAssetPath: data.heroImageAssetPath || '',
        heroVideoAssetPath: data.heroVideoAssetPath || '',
        backgroundColorHex: data.backgroundColorHex || '#66AEF8',
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
    <AdminShell
      title="Категории"
      subtitle="Добавляй новые разделы, меняй порядок, загружай tab-иконки, hero-медиа и цветовые схемы категорий."
      action={
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
              heroImageAssetPath: '',
              heroVideoAssetPath: '',
              backgroundColorHex: '#66AEF8',
            });
          }}
          className="rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700"
        >
          Добавить категорию
        </button>
      }
    >
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: 'Всего категорий', value: String(categories.length) },
          { label: 'Видимых', value: String(categories.filter((category) => category.isVisible).length) },
          { label: 'Платных', value: String(categories.filter((category) => category.isPaid).length) },
        ].map((item) => (
          <div key={item.label} className="rounded-[28px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-5">
            <div className="text-sm font-semibold text-slate-500">{item.label}</div>
            <div className="mt-3 text-3xl font-black tracking-tight text-slate-900">{item.value}</div>
          </div>
        ))}
      </div>

      <div className="mt-8">
        {error && (
          <div className="mb-4 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm text-red-900">
            Ошибка загрузки категорий: {error}
          </div>
        )}

        {(showForm || editingId) ? (
          <form
            onSubmit={handleSubmit(onSubmit)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && (e.target as HTMLElement).tagName !== 'TEXTAREA') {
                e.preventDefault();
              }
            }}
            className="mb-8 rounded-[28px] border border-slate-200 bg-white p-6 shadow-sm"
          >
            <h2 className="mb-5 text-2xl font-black tracking-tight text-slate-900">
              {editingId ? 'Редактировать категорию' : 'Новая категория'}
            </h2>
            
            <MultiLangInput
              label="Название категории"
              value={watch('title') as Record<string, string>}
              onChange={(next) => setValue('title', next as any, { shouldValidate: true })}
              placeholder="Питомцы"
            />
            {errors.title && <p className="mt-1 text-red-500 text-sm">{(errors.title as any)?.message || 'Заполни хотя бы RU'}</p>}

            <div className="mt-5 grid gap-5 xl:grid-cols-2">
              <StorageFileUpload
                path={`categories/icons/${Date.now()}.png`}
                value={watch('tabIconAssetPath')}
                onUploaded={(meta) => setValue('tabIconAssetPath', meta.url)}
                accept="image/*"
                label="Иконка для таба"
              />
              <StorageFileUpload
                path={`categories/hero/${Date.now()}.png`}
                value={watch('heroImageAssetPath')}
                onUploaded={(meta) => setValue('heroImageAssetPath', meta.url)}
                accept="image/*"
                label="Картинка над животными"
              />
            </div>

            <div className="mt-5 grid gap-5 xl:grid-cols-[1.4fr_0.8fr]">
              <StorageFileUpload
                path={`categories/hero/${Date.now()}.mp4`}
                value={watch('heroVideoAssetPath')}
                onUploaded={(meta) => setValue('heroVideoAssetPath', meta.url)}
                accept="video/mp4,video/*"
                label="Видео для главного блока категории (опционально)"
              />
              <div className="rounded-[28px] border border-slate-200 bg-slate-50 p-5">
                <label className="mb-2 block text-sm font-semibold text-slate-700">Цвет фона категории</label>
                <div className="flex items-center gap-4">
                  <input
                    type="color"
                    value={watch('backgroundColorHex') || '#66AEF8'}
                    onChange={(e) => setValue('backgroundColorHex', e.target.value)}
                    className="h-14 w-20 cursor-pointer rounded-2xl border border-slate-200 bg-white p-1"
                  />
                  <div>
                    <div className="text-sm font-semibold text-slate-900">{watch('backgroundColorHex') || '#66AEF8'}</div>
                    <div className="text-xs text-slate-500">Используется на фоне категории в приложении</div>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-5 rounded-[28px] border border-slate-200 bg-slate-50 p-5">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isPaid')} />
                <span className="font-semibold text-slate-800">Платная категория</span>
              </label>
            </div>

            {watch('isPaid') && (
              <div className="mt-5 grid gap-4 md:grid-cols-2">
                <div>
                  <label className="mb-1 block text-sm font-semibold text-slate-700">Product ID (StoreKit)</label>
                  <input
                    {...register('iapProductId')}
                    className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
                    placeholder="com.app.category_id"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-semibold text-slate-700">Цена (₽)</label>
                  <input
                    type="number"
                    step="1"
                    {...register('priceRub', { valueAsNumber: true })}
                    className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
                    placeholder="69"
                  />
                </div>
              </div>
            )}

            <div className="mt-5 rounded-[28px] border border-slate-200 bg-slate-50 p-5">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isVisible')} />
                <span className="font-semibold text-slate-800">Видима</span>
              </label>
            </div>

            <div className="mt-6 flex gap-3">
              <button type="submit" className="rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700">
                Сохранить
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowForm(false);
                  setEditingId(null);
                  reset();
                }}
                className="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
              >
                Отмена
              </button>
            </div>
          </form>
        ) : null}

        <div className="rounded-[28px] border border-slate-200 bg-white p-4 shadow-sm">
          <SortableList
            items={categories}
            onReorder={handleReorder}
            renderItem={(category) => (
              <div className="rounded-[24px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-4">
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                  <div className="flex items-center gap-4">
                    {category.tabIconAssetPath ? (
                      <img
                        src={getFileUrlFromPathOrUrl(category.tabIconAssetPath)}
                        alt={pickLocalized(category.title, "ru")}
                        className="h-14 w-14 rounded-2xl border border-slate-200 bg-white object-contain p-2"
                      />
                    ) : (
                      <div
                        className="h-14 w-14 rounded-2xl border border-slate-200"
                        style={{ backgroundColor: category.backgroundColorHex || '#66AEF8' }}
                      />
                    )}
                    <div>
                      <div className="font-black text-slate-900">{pickLocalized(category.title, "ru")}</div>
                      <div className="text-sm text-slate-500">{pickLocalized(category.title, "en")}</div>
                    </div>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                  <span
                    className="rounded-full px-3 py-1 text-xs font-bold text-slate-700"
                    style={{ backgroundColor: `${category.backgroundColorHex || '#66AEF8'}22` }}
                  >
                    {category.backgroundColorHex || '#66AEF8'}
                  </span>
                  {category.isPaid && (
                    <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-bold text-blue-800">
                      Платная
                    </span>
                  )}
                  {!category.isVisible && (
                    <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-bold text-gray-800">
                      Скрыта
                    </span>
                  )}
                  </div>
                </div>
                <div className="mt-4 flex flex-wrap gap-3">
                    <button
                      onClick={() => router.push(`/categories/${category.id}/animals`)}
                      className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 hover:text-slate-900"
                    >
                      Животные
                    </button>
                    <button
                      onClick={() => {
                        setEditingId(category.id!);
                        setShowForm(true);
                        reset(category);
                      }}
                      className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 transition hover:bg-blue-100"
                    >
                      Редактировать
                    </button>
                    <button
                      onClick={() => {
                        if (confirm('Удалить категорию?')) {
                          deleteCategory(category.id!);
                        }
                      }}
                      className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-sm font-semibold text-red-700 transition hover:bg-red-100"
                    >
                      Удалить
                    </button>
                  </div>
              </div>
            )}
          />
        </div>
      </div>
    </AdminShell>
  );
}

export default function CategoriesPage() {
  return (
    <ProtectedRoute>
      <CategoriesContent />
    </ProtectedRoute>
  );
}
