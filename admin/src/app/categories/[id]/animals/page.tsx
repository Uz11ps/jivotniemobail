'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useAnimals } from '@/hooks/useAnimals';
import { SortableList } from '@/components/SortableList';
import { Animal } from '@/types';
import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { StorageFileUpload } from '@/components/StorageFileUpload';
import { getFileUrlFromPathOrUrl } from '@/lib/storage';

const animalSchema = z.object({
  order: z.number(),
  isVisible: z.boolean(),
  name: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  topText: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  // Разрешаем пустые значения, чтобы можно было постепенно докидывать медиа.
  previewAssetPath: z.string().optional(), // иконка в сетке
  bgVideoAssetPath: z.string().optional(), // mp4 фон
  bgAssetPath: z.string().optional(), // опциональный фолбэк-картинка
  voiceAssetPath: z.object({
    ru: z.string().optional(),
    en: z.string().optional(),
  }).optional(),
  soundAssetPath: z.string().optional(), // аудио животного
  animationAssetPath: z.string().optional(),
  animationVideoAssetPath: z.string().optional(),
});

function AnimalsContent() {
  const params = useParams();
  const router = useRouter();
  const categoryId = params.id as string;
  const invalidCategoryId = !categoryId || categoryId.includes('[') || categoryId.includes(']');
  
  const { animals, loading, error, createAnimal, updateAnimal, deleteAnimal, reorderAnimals } = useAnimals(
    invalidCategoryId ? '__invalid__' : categoryId
  );
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);

  const { register, handleSubmit, reset, setValue, watch, formState: { errors } } = useForm<Animal>({
    resolver: zodResolver(animalSchema),
    defaultValues: {
      order: animals.length,
      isVisible: true,
      name: { ru: '', en: '' },
      previewAssetPath: '',
      topText: { ru: '', en: '' },
      bgVideoAssetPath: '',
      soundAssetPath: '',
    },
  });

  const onSubmit = async (data: Animal) => {
    try {
      const payload: Animal = {
        ...data,
        previewAssetPath: data.previewAssetPath || '',
        bgVideoAssetPath: data.bgVideoAssetPath || '',
        bgAssetPath: data.bgAssetPath || '',
        soundAssetPath: data.soundAssetPath || '',
      };
      if (editingId) {
        await updateAnimal(editingId, payload);
        setEditingId(null);
      } else {
        await createAnimal(payload);
        setShowForm(false);
      }
      reset();
    } catch (error) {
      console.error('Ошибка сохранения:', error);
    }
  };

  const handleReorder = async (newOrder: Animal[]) => {
    await reorderAnimals(newOrder);
  };

  // Если кто-то открыл шаблонный URL /categories/[id]/animals, показываем понятную ошибку.
  if (invalidCategoryId) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          <div className="bg-white rounded-lg shadow p-6">
            <h1 className="text-xl font-bold mb-2">Категория не выбрана</h1>
            <p className="text-gray-700 mb-4">
              Открой животных через страницу категорий (кнопка &quot;Животные&quot; у нужной категории).
            </p>
            <button
              onClick={() => router.push('/categories')}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
            >
              Перейти к категориям
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {error && (
          <div className="mb-4 rounded-lg bg-red-50 border border-red-200 p-3 text-sm text-red-900">
            Ошибка загрузки животных: {error}
          </div>
        )}
        <div className="flex justify-between items-center mb-6">
          <div>
            <button onClick={() => router.push('/categories')} className="text-blue-600 mb-2">
              ← Назад к категориям
            </button>
            <h1 className="text-2xl font-bold">Животные в категории</h1>
          </div>
          <button
            onClick={() => {
              setShowForm(true);
              setEditingId(null);
              reset({
                order: animals.length,
                isVisible: true,
                name: { ru: '', en: '' },
                topText: { ru: '', en: '' },
                previewAssetPath: '',
                bgVideoAssetPath: '',
                soundAssetPath: '',
              });
            }}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Добавить животное
          </button>
        </div>

        {(showForm || editingId) && (
          <form
            onSubmit={handleSubmit(onSubmit)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && (e.target as HTMLElement).tagName !== 'TEXTAREA') {
                e.preventDefault();
              }
            }}
            className="bg-white p-6 rounded-lg shadow mb-6"
          >
            <h2 className="text-lg font-semibold mb-4">
              {editingId ? 'Редактировать животное' : 'Новое животное'}
            </h2>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Название (RU)</label>
                <input {...register('name.ru')} className="w-full border rounded px-3 py-2" />
                {errors.name?.ru && <p className="text-red-500 text-sm">{errors.name.ru.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Название (EN)</label>
                <input {...register('name.en')} className="w-full border rounded px-3 py-2" />
                {errors.name?.en && <p className="text-red-500 text-sm">{errors.name.en.message}</p>}
              </div>
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/icons/${Date.now()}.png`}
                value={watch('previewAssetPath')}
                onUploaded={(meta) => setValue('previewAssetPath', meta.url)}
                accept="image/*"
                label="Иконка животного (для сетки)"
              />
              {watch('previewAssetPath') && (
                <img
                  src={getFileUrlFromPathOrUrl(watch('previewAssetPath'))}
                  alt="Icon"
                  className="w-16 h-16 mt-2 rounded"
                />
              )}
            </div>

            <div className="mb-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Текст сверху (RU)</label>
                  <input {...register('topText.ru')} className="w-full border rounded px-3 py-2" placeholder="Кот/кошка" />
                  {errors.topText?.ru && <p className="text-red-500 text-sm">{errors.topText.ru.message}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Текст сверху (EN)</label>
                  <input {...register('topText.en')} className="w-full border rounded px-3 py-2" placeholder="Cat" />
                  {errors.topText?.en && <p className="text-red-500 text-sm">{errors.topText.en.message}</p>}
                </div>
              </div>
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/backgroundVideo/${Date.now()}.mp4`}
                value={watch('bgVideoAssetPath')}
                onUploaded={(meta) => setValue('bgVideoAssetPath', meta.url)}
                accept="video/mp4,video/*"
                label="Фон-видео (mp4)"
              />
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/backgrounds/${Date.now()}.png`}
                value={watch('bgAssetPath')}
                onUploaded={(meta) => setValue('bgAssetPath', meta.url)}
                accept="image/*"
                label="Фон-картинка (опционально, fallback)"
              />
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/audio/${Date.now()}.mp3`}
                value={watch('soundAssetPath')}
                onUploaded={(meta) => setValue('soundAssetPath', meta.url)}
                accept="audio/*"
                label="Аудио животного"
              />
              {watch('soundAssetPath') && (
                <audio
                  src={getFileUrlFromPathOrUrl(watch('soundAssetPath')!)}
                  controls
                  className="mt-2 w-full"
                />
              )}
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/voices/${Date.now()}-ru.mp3`}
                value={watch('voiceAssetPath')?.ru}
                onUploaded={(meta) => setValue('voiceAssetPath.ru', meta.url)}
                accept="audio/*"
                label="Голос (RU) - опционально"
              />
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/voices/${Date.now()}-en.mp3`}
                value={watch('voiceAssetPath')?.en}
                onUploaded={(meta) => setValue('voiceAssetPath.en', meta.url)}
                accept="audio/*"
                label="Голос (EN) - опционально"
              />
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/animations/${Date.now()}.lottie`}
                value={watch('animationAssetPath')}
                onUploaded={(meta) => setValue('animationAssetPath', meta.url)}
                accept=".lottie,application/json"
                label="Анимация (Lottie) - опционально"
              />
            </div>

            <div className="mb-4">
              <StorageFileUpload
                path={`animals/animations/${Date.now()}.mp4`}
                value={watch('animationVideoAssetPath')}
                onUploaded={(meta) => setValue('animationVideoAssetPath', meta.url)}
                accept="video/mp4,video/*"
                label="Анимация (Video) - опционально"
              />
            </div>

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isVisible')} />
                <span>Видимо</span>
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
            items={animals}
            onReorder={handleReorder}
            renderItem={(animal) => (
              <div className="flex items-center justify-between p-4 border-b">
                <div className="flex items-center gap-4">
                  {animal.previewAssetPath && (
                    <img
                      src={getFileUrlFromPathOrUrl(animal.previewAssetPath)}
                      alt={animal.name.ru}
                      className="w-16 h-16 rounded"
                    />
                  )}
                  <span className="font-semibold">{animal.name.ru}</span>
                  {!animal.isVisible && (
                    <span className="bg-gray-100 text-gray-800 text-xs px-2 py-1 rounded">
                      Скрыто
                    </span>
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      setEditingId(animal.id!);
                      setShowForm(true);
                      reset(animal);
                    }}
                    className="text-blue-600 hover:text-blue-800"
                  >
                    Редактировать
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('Удалить животное?')) {
                        deleteAnimal(animal.id!);
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

export default function AnimalsPage() {
  return (
    <ProtectedRoute>
      <AnimalsContent />
    </ProtectedRoute>
  );
}
