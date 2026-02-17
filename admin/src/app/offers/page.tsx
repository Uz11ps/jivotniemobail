'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useOffers } from '@/hooks/useOffers';
import { Offer, OfferItem } from '@/types';
import { useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FileUpload } from '@/components/FileUpload';

const offerSchema = z.object({
  isActive: z.boolean(),
  title: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  heroAssets: z.array(z.string()),
  items: z.array(z.object({
    label: z.object({
      ru: z.string().min(1),
      en: z.string().min(1),
    }),
    productId: z.string().min(1),
    badge: z.object({
      ru: z.string().optional(),
      en: z.string().optional(),
    }).optional(),
  })),
  primaryProductId: z.string().min(1),
});

function OffersContent() {
  const { offers, loading, createOffer, updateOffer, deleteOffer } = useOffers();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);

  const { register, handleSubmit, reset, setValue, watch, control, formState: { errors } } = useForm<Offer>({
    resolver: zodResolver(offerSchema),
    defaultValues: {
      isActive: true,
      title: { ru: '', en: '' },
      heroAssets: [],
      items: [],
      primaryProductId: '',
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'items',
  });

  // react-hook-form типизирует useFieldArray под массивы объектов.
  // heroAssets у нас string[], поэтому здесь безопасно используем any.
  const { fields: heroFields, append: appendHero, remove: removeHero } = useFieldArray({
    control: control as any,
    name: 'heroAssets' as any,
  });

  const onSubmit = async (data: Offer) => {
    try {
      if (editingId) {
        await updateOffer(editingId, data);
        setEditingId(null);
      } else {
        await createOffer(data);
        setShowForm(false);
      }
      reset();
    } catch (error) {
      console.error('Ошибка сохранения:', error);
    }
  };

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Офферы</h1>
          <button
            onClick={() => {
              setShowForm(true);
              setEditingId(null);
              reset({ isActive: true, title: { ru: '', en: '' }, heroAssets: [], items: [], primaryProductId: '' });
            }}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Добавить оффер
          </button>
        </div>

        {(showForm || editingId) && (
          <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">
              {editingId ? 'Редактировать оффер' : 'Новый оффер'}
            </h2>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Заголовок (RU)</label>
                <input {...register('title.ru')} className="w-full border rounded px-3 py-2" />
                {errors.title?.ru && <p className="text-red-500 text-sm">{errors.title.ru.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Заголовок (EN)</label>
                <input {...register('title.en')} className="w-full border rounded px-3 py-2" />
                {errors.title?.en && <p className="text-red-500 text-sm">{errors.title.en.message}</p>}
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">Hero изображения</label>
              {heroFields.map((field, index) => (
                <div key={field.id} className="flex gap-2 mb-2">
                  <FileUpload
                    path={`offers/hero/${Date.now()}-${index}.png`}
                    onUploaded={(url) => {
                      const current = watch('heroAssets');
                      current[index] = url;
                      setValue('heroAssets', current);
                    }}
                    accept="image/*"
                  />
                  <button type="button" onClick={() => removeHero(index)} className="text-red-600">
                    Удалить
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => appendHero('')}
                className="text-blue-600 text-sm"
              >
                + Добавить изображение
              </button>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">Элементы оффера</label>
              {fields.map((field, index) => (
                <div key={field.id} className="border p-4 mb-2 rounded">
                  <div className="grid grid-cols-2 gap-2 mb-2">
                    <input
                      {...register(`items.${index}.label.ru`)}
                      placeholder="Название (RU)"
                      className="border rounded px-2 py-1"
                    />
                    <input
                      {...register(`items.${index}.label.en`)}
                      placeholder="Название (EN)"
                      className="border rounded px-2 py-1"
                    />
                  </div>
                  <input
                    {...register(`items.${index}.productId`)}
                    placeholder="Product ID"
                    className="border rounded px-2 py-1 w-full mb-2"
                  />
                  <div className="grid grid-cols-2 gap-2 mb-2">
                    <input
                      {...register(`items.${index}.badge.ru`)}
                      placeholder="Бейдж (RU) - опционально"
                      className="border rounded px-2 py-1"
                    />
                    <input
                      {...register(`items.${index}.badge.en`)}
                      placeholder="Бейдж (EN) - опционально"
                      className="border rounded px-2 py-1"
                    />
                  </div>
                  <button
                    type="button"
                    onClick={() => remove(index)}
                    className="text-red-600 text-sm"
                  >
                    Удалить элемент
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => append({ label: { ru: '', en: '' }, productId: '' })}
                className="text-blue-600 text-sm"
              >
                + Добавить элемент
              </button>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Primary Product ID</label>
              <input {...register('primaryProductId')} className="w-full border rounded px-3 py-2" />
            </div>

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isActive')} />
                <span>Активен</span>
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
          {offers.map((offer) => (
            <div key={offer.id} className="p-4 border-b flex items-center justify-between">
              <div>
                <span className="font-semibold">{offer.title.ru}</span>
                {!offer.isActive && (
                  <span className="bg-gray-100 text-gray-800 text-xs px-2 py-1 rounded ml-2">
                    Неактивен
                  </span>
                )}
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    setEditingId(offer.id!);
                    setShowForm(true);
                    reset(offer);
                  }}
                  className="text-blue-600 hover:text-blue-800"
                >
                  Редактировать
                </button>
                <button
                  onClick={() => {
                    if (confirm('Удалить оффер?')) {
                      deleteOffer(offer.id!);
                    }
                  }}
                  className="text-red-600 hover:text-red-800"
                >
                  Удалить
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function OffersPage() {
  return (
    <ProtectedRoute>
      <OffersContent />
    </ProtectedRoute>
  );
}
