'use client';

import { useState } from 'react';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useParentalTests } from '@/hooks/useParentalTests';
import { ParentalTest } from '@/types';

const parentalTestSchema = z
  .object({
    order: z.number().int().min(0),
    isActive: z.boolean(),
    left: z.number().int().min(0),
    right: z.number().int().min(0),
    operator: z.union([z.literal('+'), z.literal('-')]),
    answers: z.array(z.number().int()).length(4),
    correctAnswer: z.number().int(),
  })
  .refine((v) => v.answers.includes(v.correctAnswer), {
    message: 'Правильный ответ должен быть среди вариантов',
    path: ['correctAnswer'],
  });

function ParentalTestsContent() {
  const { tests, loading, createTest, updateTest, deleteTest } = useParentalTests();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<ParentalTest>({
    resolver: zodResolver(parentalTestSchema),
    defaultValues: {
      order: 0,
      isActive: true,
      left: 2,
      right: 7,
      operator: '+',
      answers: [8, 5, 9, 6],
      correctAnswer: 9,
    },
  });

  const onSubmit = async (data: ParentalTest) => {
    try {
      if (editingId) {
        await updateTest(editingId, data);
        setEditingId(null);
      } else {
        await createTest(data);
        setShowForm(false);
      }
      reset();
    } catch (error) {
      console.error('Ошибка сохранения теста:', error);
    }
  };

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Родительский контроль</h1>
          <button
            onClick={() => {
              setShowForm(true);
              setEditingId(null);
              reset({
                order: tests.length,
                isActive: true,
                left: 2,
                right: 7,
                operator: '+',
                answers: [8, 5, 9, 6],
                correctAnswer: 9,
              });
            }}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Добавить тест
          </button>
        </div>

        {(showForm || editingId) && (
          <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">
              {editingId ? 'Редактировать тест' : 'Новый тест'}
            </h2>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Порядок</label>
                <input type="number" {...register('order', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Число 1</label>
                <input type="number" {...register('left', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Операция</label>
                <select {...register('operator')} className="w-full border rounded px-3 py-2">
                  <option value="+">+</option>
                  <option value="-">-</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Число 2</label>
                <input type="number" {...register('right', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Вариант 1</label>
                <input type="number" {...register('answers.0', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Вариант 2</label>
                <input type="number" {...register('answers.1', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Вариант 3</label>
                <input type="number" {...register('answers.2', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Вариант 4</label>
                <input type="number" {...register('answers.3', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-1">Правильный ответ</label>
                <input type="number" {...register('correctAnswer', { valueAsNumber: true })} className="w-full border rounded px-3 py-2" />
                {errors.correctAnswer && (
                  <p className="text-sm text-red-600 mt-1">{errors.correctAnswer.message}</p>
                )}
              </div>
              <div className="flex items-end pb-2">
                <label className="flex items-center gap-2">
                  <input type="checkbox" {...register('isActive')} />
                  <span>Активен</span>
                </label>
              </div>
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
          {tests.map((test) => (
            <div key={test.id} className="p-4 border-b flex items-center justify-between">
              <div>
                <div className="font-semibold">
                  {test.left} {test.operator} {test.right} = ?
                </div>
                <div className="text-sm text-gray-600">
                  Варианты: {test.answers.join(', ')} | Правильный: {test.correctAnswer}
                </div>
              </div>
              <div className="flex gap-2">
                {!test.isActive && (
                  <span className="bg-gray-100 text-gray-800 text-xs px-2 py-1 rounded h-fit mt-1">
                    Неактивен
                  </span>
                )}
                <button
                  onClick={() => {
                    setEditingId(test.id!);
                    setShowForm(true);
                    reset(test);
                  }}
                  className="text-blue-600 hover:text-blue-800"
                >
                  Редактировать
                </button>
                <button
                  onClick={() => {
                    if (confirm('Удалить тест?')) {
                      deleteTest(test.id!);
                    }
                  }}
                  className="text-red-600 hover:text-red-800"
                >
                  Удалить
                </button>
              </div>
            </div>
          ))}
          {tests.length === 0 && (
            <div className="p-4 text-gray-600">Пока нет тестов. Добавьте первый тест выше.</div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function ParentalTestsPage() {
  return (
    <ProtectedRoute>
      <ParentalTestsContent />
    </ProtectedRoute>
  );
}

