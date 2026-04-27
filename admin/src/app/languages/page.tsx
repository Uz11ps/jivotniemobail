'use client';

import { useMemo, useState } from 'react';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { AdminShell } from '@/components/AdminShell';
import { SortableList } from '@/components/SortableList';
import { useLanguages } from '@/hooks/useLanguages';
import type { AppLanguage } from '@/lib/languages';

function LanguagesContent() {
  const {
    languages,
    loading,
    error,
    createLanguage,
    updateLanguage,
    deleteLanguage,
    reorderLanguages,
    seedDefaults,
  } = useLanguages();

  const [editingCode, setEditingCode] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [formCode, setFormCode] = useState('');
  const [formName, setFormName] = useState('');
  const [formFlag, setFormFlag] = useState('🏳️');
  const [formRequired, setFormRequired] = useState(false);
  const [busy, setBusy] = useState(false);

  const isFirestoreEmpty = languages.length === 0 || (error && error.includes('Firestore'));
  const requiredCount = useMemo(
    () => languages.filter((l) => l.required).length,
    [languages]
  );

  const resetForm = () => {
    setFormCode('');
    setFormName('');
    setFormFlag('🏳️');
    setFormRequired(false);
    setEditingCode(null);
    setShowForm(false);
  };

  const startEdit = (lang: AppLanguage) => {
    setFormCode(lang.code);
    setFormName(lang.nameRu);
    setFormFlag(lang.flag || '🏳️');
    setFormRequired(!!lang.required);
    setEditingCode(lang.code);
    setShowForm(true);
  };

  const submit = async () => {
    const code = formCode.trim().toLowerCase();
    if (!/^[a-z]{2}$/.test(code)) {
      alert('Код должен быть ровно 2 латинские буквы (ISO 639-1): ru, en, es, …');
      return;
    }
    if (!formName.trim()) {
      alert('Введи название на русском');
      return;
    }
    setBusy(true);
    try {
      if (editingCode) {
        await updateLanguage(editingCode, {
          nameRu: formName.trim(),
          flag: formFlag || '🏳️',
          required: formRequired,
        });
      } else {
        await createLanguage({
          code,
          nameRu: formName.trim(),
          flag: formFlag || '🏳️',
          required: formRequired,
        });
      }
      resetForm();
    } catch (err) {
      alert(`Ошибка: ${err instanceof Error ? err.message : err}`);
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async (lang: AppLanguage) => {
    if (lang.required) {
      if (!confirm(`«${lang.nameRu}» помечен как обязательный. Точно удалить?`)) return;
    } else {
      if (!confirm(`Удалить язык «${lang.nameRu}» (${lang.code})?`)) return;
    }
    setBusy(true);
    try {
      await deleteLanguage(lang.code);
    } catch (err) {
      alert(`Ошибка удаления: ${err instanceof Error ? err.message : err}`);
    } finally {
      setBusy(false);
    }
  };

  const handleSeed = async () => {
    if (!confirm('Заполнить список 15 языками по умолчанию (RU, EN, ES, PT, …)? Уже существующие не будут затронуты.')) return;
    setBusy(true);
    try {
      await seedDefaults();
    } catch (err) {
      alert(`Не удалось засеять: ${err instanceof Error ? err.message : err}`);
    } finally {
      setBusy(false);
    }
  };

  const handleReorder = async (newOrder: AppLanguage[]) => {
    try {
      await reorderLanguages(newOrder);
    } catch (err) {
      alert(`Не удалось сохранить порядок: ${err instanceof Error ? err.message : err}`);
    }
  };

  // SortableList expects items with `.id`. Map code → id.
  const sortableItems = useMemo(
    () => languages.map((l) => ({ ...l, id: l.code })),
    [languages]
  );

  if (loading) return <div className="p-8">Загрузка...</div>;

  return (
    <AdminShell
      title="Языки контента"
      subtitle="Заказчик сам управляет списком поддерживаемых языков. Их видно в формах названий и в загрузке озвучки."
      action={
        <button
          onClick={() => {
            resetForm();
            setShowForm(true);
          }}
          className="rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700"
        >
          + Добавить язык
        </button>
      }
    >
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: 'Всего языков', value: String(languages.length) },
          { label: 'Обязательных', value: String(requiredCount) },
          { label: 'Опциональных', value: String(languages.length - requiredCount) },
        ].map((item) => (
          <div
            key={item.label}
            className="rounded-[28px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-5"
          >
            <div className="text-sm font-semibold text-slate-500">{item.label}</div>
            <div className="mt-3 text-3xl font-black tracking-tight text-slate-900">{item.value}</div>
          </div>
        ))}
      </div>

      {isFirestoreEmpty && (
        <div className="mt-6 rounded-[28px] border border-amber-200 bg-amber-50 p-5">
          <div className="font-bold text-amber-900">Список пуст</div>
          <p className="mt-1 text-sm text-amber-800">
            В Firestore ещё нет языков — пока используется встроенный набор по умолчанию (15 языков).
            Нажми «Заполнить дефолтами» чтобы создать их в Firestore — после этого ты сможешь редактировать,
            добавлять новые и менять порядок.
          </p>
          <button
            onClick={handleSeed}
            disabled={busy}
            className="mt-3 rounded-2xl bg-amber-600 px-4 py-2 text-sm font-bold text-white transition hover:bg-amber-700 disabled:opacity-60"
          >
            Заполнить дефолтами (15 языков)
          </button>
        </div>
      )}

      {error && !isFirestoreEmpty && (
        <div className="mt-6 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm text-red-900">
          {error}
        </div>
      )}

      {showForm && (
        <div className="mt-6 rounded-[28px] border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="mb-5 text-2xl font-black tracking-tight text-slate-900">
            {editingCode ? `Редактировать «${editingCode}»` : 'Новый язык'}
          </h2>

          <div className="grid gap-4 md:grid-cols-[120px_1fr_120px]">
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-700">
                Код (ISO 639-1)
              </label>
              <input
                value={formCode}
                disabled={!!editingCode}
                onChange={(e) => setFormCode(e.target.value.toLowerCase().slice(0, 2))}
                placeholder="ru"
                maxLength={2}
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60 disabled:bg-slate-50 disabled:text-slate-500"
              />
              <div className="mt-1 text-xs text-slate-400">2 буквы, нижний регистр</div>
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-700">
                Название (на русском)
              </label>
              <input
                value={formName}
                onChange={(e) => setFormName(e.target.value)}
                placeholder="Русский"
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              />
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-700">
                Флаг (emoji)
              </label>
              <input
                value={formFlag}
                onChange={(e) => setFormFlag(e.target.value)}
                placeholder="🇷🇺"
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-center text-2xl outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              />
            </div>
          </div>

          <label className="mt-5 flex items-center gap-2">
            <input
              type="checkbox"
              checked={formRequired}
              onChange={(e) => setFormRequired(e.target.checked)}
            />
            <span className="font-semibold text-slate-800">
              Обязательный — нельзя сохранить категорию или животное без перевода на этот язык
            </span>
          </label>

          <div className="mt-6 flex gap-3">
            <button
              type="button"
              onClick={submit}
              disabled={busy}
              className="rounded-2xl bg-slate-900 px-5 py-3 text-sm font-bold text-white transition hover:bg-slate-700 disabled:opacity-60"
            >
              {editingCode ? 'Сохранить' : 'Добавить'}
            </button>
            <button
              type="button"
              onClick={resetForm}
              className="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
            >
              Отмена
            </button>
          </div>
        </div>
      )}

      <div className="mt-6 rounded-[28px] border border-slate-200 bg-white p-4 shadow-sm">
        <div className="mb-3 px-2 text-sm text-slate-500">
          Перетаскивай строки чтобы изменить порядок. Этот порядок виден в формах животных и категорий.
        </div>
        <SortableList
          items={sortableItems}
          onReorder={(items) => handleReorder(items as AppLanguage[])}
          renderItem={(lang: AppLanguage & { id: string }) => (
            <div className="flex items-center gap-4 rounded-[24px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-4">
              <div className="text-3xl">{lang.flag}</div>
              <div className="flex-1">
                <div className="font-black text-slate-900">{lang.nameRu}</div>
                <div className="text-xs text-slate-500">
                  Код: <code className="rounded bg-slate-100 px-1">{lang.code}</code>
                </div>
              </div>
              {lang.required && (
                <span className="rounded-full bg-rose-100 px-3 py-1 text-xs font-bold text-rose-800">
                  Обязательный
                </span>
              )}
              <button
                onClick={() => startEdit(lang)}
                className="rounded-2xl border border-blue-200 bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 transition hover:bg-blue-100"
              >
                Редактировать
              </button>
              <button
                onClick={() => handleDelete(lang)}
                disabled={busy}
                className="rounded-2xl border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-700 transition hover:bg-red-100 disabled:opacity-60"
              >
                Удалить
              </button>
            </div>
          )}
        />
      </div>
    </AdminShell>
  );
}

export default function LanguagesPage() {
  return (
    <ProtectedRoute>
      <LanguagesContent />
    </ProtectedRoute>
  );
}
