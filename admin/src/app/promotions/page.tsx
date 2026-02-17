'use client';

import { useState } from 'react';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { usePromotions } from '@/hooks/usePromotions';
import { Promotion } from '@/types';

const promotionSchema = z.object({
  order: z.number().int().min(0),
  isActive: z.boolean(),
  title: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  message: z.object({
    ru: z.string().min(1),
    en: z.string().min(1),
  }),
  discountPercent: z.number().int().min(1).max(100),
  target: z.union([z.literal('all'), z.literal('device')]),
  deviceIds: z.array(z.string()),
  startsAt: z.string().nullable().optional(),
  endsAt: z.string().nullable().optional(),
});

type PromotionForm = Omit<Promotion, 'id' | 'deviceIds'> & {
  deviceIdsText: string;
};

function toDatetimeLocalValue(v?: string | null): string {
  if (!v) return '';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return '';
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
}

function PromotionsContent() {
  const { promotions, loading, createPromotion, updatePromotion, deletePromotion } = usePromotions();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);

  const { register, handleSubmit, reset, watch, formState: { errors } } = useForm<PromotionForm>({
    resolver: zodResolver(
      promotionSchema.extend({
        deviceIdsText: z.string(),
      }) as any
    ),
    defaultValues: {
      order: 0,
      isActive: true,
      title: { ru: '', en: '' },
      message: { ru: '', en: '' },
      discountPercent: 37,
      target: 'all',
      deviceIdsText: '',
      startsAt: null,
      endsAt: null,
    },
  });

  const onSubmit = async (data: PromotionForm) => {
    const deviceIds = data.deviceIdsText
      .split('\n')
      .map((v) => v.trim())
      .filter(Boolean);
    const payload: Omit<Promotion, 'id'> = {
      order: data.order,
      isActive: data.isActive,
      title: data.title,
      message: data.message,
      discountPercent: data.discountPercent,
      target: data.target,
      deviceIds,
      startsAt: data.startsAt && data.startsAt.length > 0 ? new Date(data.startsAt).toISOString() : null,
      endsAt: data.endsAt && data.endsAt.length > 0 ? new Date(data.endsAt).toISOString() : null,
    };
    try {
      if (editingId) {
        await updatePromotion(editingId, payload);
        setEditingId(null);
      } else {
        await createPromotion(payload);
        setShowForm(false);
      }
      reset();
    } catch (error) {
      console.error('Ошибка сохранения акции:', error);
    }
  };

  if (loading) return <div className="p-8">Загрузка...</div>;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Скидки и акции</h1>
          <button
            onClick={() => {
              setShowForm(true);
              setEditingId(null);
              reset({
                order: promotions.length,
                isActive: true,
                title: { ru: '', en: '' },
                message: { ru: '', en: '' },
                discountPercent: 37,
                target: 'all',
                deviceIdsText: '',
                startsAt: null,
                endsAt: null,
              });
            }}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Добавить акцию
          </button>
        </div>

        {(showForm || editingId) && (
          <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">
              {editingId ? 'Редактировать акцию' : 'Новая акция'}
            </h2>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Заголовок (RU)</label>
                <input {...register('title.ru')} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Заголовок (EN)</label>
                <input {...register('title.en')} className="w-full border rounded px-3 py-2" />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Текст баннера (RU)</label>
                <textarea {...register('message.ru')} className="w-full border rounded px-3 py-2" rows={2} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Текст баннера (EN)</label>
                <textarea {...register('message.en')} className="w-full border rounded px-3 py-2" rows={2} />
              </div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Порядок</label>
                <input type="number" {...register('order', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Скидка %</label>
                <input type="number" {...register('discountPercent', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Старт</label>
                <input type="datetime-local" {...register('startsAt')} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Окончание</label>
                <input type="datetime-local" {...register('endsAt')} className="w-full border rounded px-3 py-2" />
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Таргет</label>
              <select {...register('target')} className="w-full border rounded px-3 py-2">
                <option value="all">Все пользователи</option>
                <option value="device">Только указанные deviceId</option>
              </select>
            </div>

            {watch('target') === 'device' && (
              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">Device IDs (по одному в строке)</label>
                <textarea
                  {...register('deviceIdsText')}
                  rows={4}
                  placeholder="device-abc123&#10;device-xyz456"
                  className="w-full border rounded px-3 py-2"
                />
              </div>
            )}

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...register('isActive')} />
                <span>Активна</span>
              </label>
              {errors.discountPercent && <p className="text-sm text-red-600 mt-1">{errors.discountPercent.message}</p>}
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
          {promotions.map((promo) => (
            <div key={promo.id} className="p-4 border-b flex items-center justify-between">
              <div>
                <div className="font-semibold">{promo.title.ru} ({promo.discountPercent}%)</div>
                <div className="text-sm text-gray-600">{promo.message.ru}</div>
                <div className="text-xs text-gray-500 mt-1">
                  target: {promo.target} | order: {promo.order}
                </div>
              </div>
              <div className="flex gap-2 items-start">
                {!promo.isActive && (
                  <span className="bg-gray-100 text-gray-800 text-xs px-2 py-1 rounded mt-1">Неактивна</span>
                )}
                <button
                  onClick={() => {
                    setEditingId(promo.id!);
                    setShowForm(true);
                    reset({
                      order: promo.order,
                      isActive: promo.isActive,
                      title: promo.title,
                      message: promo.message,
                      discountPercent: promo.discountPercent,
                      target: promo.target,
                      deviceIdsText: (promo.deviceIds || []).join('\n'),
                      startsAt: toDatetimeLocalValue(promo.startsAt),
                      endsAt: toDatetimeLocalValue(promo.endsAt),
                    });
                  }}
                  className="text-blue-600 hover:text-blue-800"
                >
                  Редактировать
                </button>
                <button
                  onClick={() => {
                    if (confirm('Удалить акцию?')) {
                      deletePromotion(promo.id!);
                    }
                  }}
                  className="text-red-600 hover:text-red-800"
                >
                  Удалить
                </button>
              </div>
            </div>
          ))}
          {promotions.length === 0 && (
            <div className="p-4 text-gray-600">Пока нет акций. Добавьте первую выше.</div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function PromotionsPage() {
  return (
    <ProtectedRoute>
      <PromotionsContent />
    </ProtectedRoute>
  );
}

