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
import { MultiLangInput } from '@/components/MultiLangInput';
import { MultiLangAudioUpload } from '@/components/MultiLangAudioUpload';
import { getFileUrlFromPathOrUrl } from '@/lib/storage';
import { AdminShell } from '@/components/AdminShell';
import { pickLocalized } from '@/lib/languages';

const animalSchema = z.object({
  order: z.number(),
  isVisible: z.boolean(),
  // Multilang strings: validated as objects with at least ru filled.
  name: z.record(z.string()).refine((v) => !!v.ru && v.ru.length > 0, {
    message: 'RU обязателен',
  }),
  topText: z.record(z.string()).optional(),
  // Разрешаем пустые значения, чтобы можно было постепенно докидывать медиа.
  previewAssetPath: z.string().optional(), // иконка в сетке
  bgVideoAssetPath: z.string().optional(), // mp4 фон
  bgAssetPath: z.string().optional(), // опциональный фолбэк-картинка
  voiceAssetPath: z.record(z.string()).optional(), // голос на каждый язык
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
      name: { ru: '', en: '' } as any,
      previewAssetPath: '',
      topText: { ru: '', en: '' } as any,
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
      <AdminShell
        title="Животные"
        subtitle="Категория не выбрана. Открой животных через экран категорий."
      >
        <div className="rounded-[28px] border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-2xl font-black tracking-tight text-slate-900">Категория не выбрана</h2>
          <p className="mt-2 text-sm text-slate-500">
            Открой животных через страницу категорий по кнопке &quot;Животные&quot; у нужной категории.
          </p>
          <button
            onClick={() => router.push('/categories')}
            className="mt-5 rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700"
          >
            Перейти к категориям
          </button>
        </div>
      </AdminShell>
    );
  }

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <AdminShell
      title="Животные категории"
      subtitle={`Управление карточками, видео, аудио и порядком показа для категории ${categoryId}.`}
      action={
        <button
          onClick={() => {
            setShowForm(true);
            setEditingId(null);
            reset({
              order: animals.length,
              isVisible: true,
              name: { ru: '', en: '' } as any,
              topText: { ru: '', en: '' } as any,
              previewAssetPath: '',
              bgVideoAssetPath: '',
              soundAssetPath: '',
            });
          }}
          className="rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700"
        >
          Добавить животное
        </button>
      }
    >
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: 'Всего животных', value: String(animals.length) },
          { label: 'Видимых', value: String(animals.filter((animal) => animal.isVisible).length) },
          { label: 'С медиа', value: String(animals.filter((animal) => animal.previewAssetPath || animal.bgVideoAssetPath || animal.soundAssetPath).length) },
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
            Ошибка загрузки животных: {error}
          </div>
        )}

        <button
          onClick={() => router.push('/categories')}
          className="mb-5 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
        >
          ← Назад к категориям
        </button>

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
              {editingId ? 'Редактировать животное' : 'Новое животное'}
            </h2>
            
            <MultiLangInput
              label="Название животного"
              value={watch('name') as Record<string, string>}
              onChange={(next) => setValue('name', next as any, { shouldValidate: true })}
              placeholder="Кот"
            />
            {errors.name && <p className="mt-1 text-red-500 text-sm">{(errors.name as any)?.message || 'Заполни хотя бы RU'}</p>}

            <div className="mt-5">
              <StorageFileUpload
                path={`animals/icons/${Date.now()}.png`}
                value={watch('previewAssetPath')}
                onUploaded={(meta) => setValue('previewAssetPath', meta.url)}
                accept="image/*"
                label="Иконка животного (для сетки)"
              />
            </div>

            <div className="mt-5">
              <MultiLangInput
                label="Текст сверху (опционально)"
                value={watch('topText') as Record<string, string>}
                onChange={(next) => setValue('topText', next as any)}
                placeholder="Кот/кошка"
              />
            </div>

            <div className="mt-5 grid gap-5 xl:grid-cols-2">
              <StorageFileUpload
                path={`animals/backgroundVideo/${Date.now()}.mp4`}
                value={watch('bgVideoAssetPath')}
                onUploaded={(meta) => setValue('bgVideoAssetPath', meta.url)}
                accept="video/mp4,video/*"
                label="Фон-видео (mp4)"
              />
              <StorageFileUpload
                path={`animals/backgrounds/${Date.now()}.png`}
                value={watch('bgAssetPath')}
                onUploaded={(meta) => setValue('bgAssetPath', meta.url)}
                accept="image/*"
                label="Фон-картинка (опционально, fallback)"
              />
            </div>

            <div className="mt-5">
              <StorageFileUpload
                path={`animals/audio/${Date.now()}.mp3`}
                value={watch('soundAssetPath')}
                onUploaded={(meta) => setValue('soundAssetPath', meta.url)}
                accept="audio/*"
                label="Аудио животного"
              />
            </div>

            <div className="mt-5">
              <MultiLangAudioUpload
                label="Озвучка названия (15 языков)"
                basePath={`animals/voices/${editingId || 'new'}`}
                value={watch('voiceAssetPath') as Record<string, string>}
                onChange={(next) => setValue('voiceAssetPath', next as any)}
              />
            </div>

            <div className="mt-5 grid gap-5 xl:grid-cols-2">
              <StorageFileUpload
                path={`animals/animations/${Date.now()}.lottie`}
                value={watch('animationAssetPath')}
                onUploaded={(meta) => setValue('animationAssetPath', meta.url)}
                accept=".lottie,application/json"
                label="Анимация (Lottie) - опционально"
              />
              <StorageFileUpload
                path={`animals/animations/${Date.now()}.mp4`}
                value={watch('animationVideoAssetPath')}
                onUploaded={(meta) => setValue('animationVideoAssetPath', meta.url)}
                accept="video/mp4,video/*"
                label="Анимация (Video) - опционально"
              />
            </div>

            <div className="mt-5 rounded-[28px] border border-slate-200 bg-slate-50 p-5">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isVisible')} />
                <span className="font-semibold text-slate-800">Видимо</span>
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
            items={animals}
            onReorder={handleReorder}
            renderItem={(animal) => (
              <div className="rounded-[24px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-4">
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                  <div className="flex items-center gap-4">
                  {animal.previewAssetPath && (
                    <img
                      src={getFileUrlFromPathOrUrl(animal.previewAssetPath)}
                      alt={pickLocalized(animal.name, "ru")}
                      className="h-16 w-16 rounded-2xl border border-slate-200 bg-white object-contain p-2"
                    />
                  )}
                    <div>
                      <div className="font-black text-slate-900">{pickLocalized(animal.name, "ru")}</div>
                      <div className="text-sm text-slate-500">{pickLocalized(animal.name, "en")}</div>
                    </div>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    {animal.bgVideoAssetPath ? (
                      <span className="rounded-full bg-violet-100 px-3 py-1 text-xs font-bold text-violet-800">Видео</span>
                    ) : null}
                    {animal.soundAssetPath ? (
                      <span className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-800">Аудио</span>
                    ) : null}
                  {!animal.isVisible && (
                    <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-bold text-gray-800">
                      Скрыто
                    </span>
                  )}
                  </div>
                </div>
                <div className="mt-4 flex flex-wrap gap-3">
                    <button
                      onClick={() => {
                        setEditingId(animal.id!);
                        setShowForm(true);
                        reset(animal);
                      }}
                      className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 transition hover:bg-blue-100"
                    >
                      Редактировать
                    </button>
                    <button
                      onClick={() => {
                        if (confirm('Удалить животное?')) {
                          deleteAnimal(animal.id!);
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

export default function AnimalsPage() {
  return (
    <ProtectedRoute>
      <AnimalsContent />
    </ProtectedRoute>
  );
}
