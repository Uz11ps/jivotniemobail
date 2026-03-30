'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export default function LoginPage() {
  const { user, signIn, loading } = useAuth();
  const router = useRouter();
  const [username, setUsername] = useState('123');
  const [password, setPassword] = useState('123');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (user) {
      router.push('/dashboard');
    }
  }, [user, router]);

  const handleSignIn = async () => {
    try {
      setSubmitting(true);
      await signIn(username, password);
      router.push('/dashboard');
    } catch (error) {
      console.error('Ошибка входа:', error);
      alert('Неверный логин или пароль');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[radial-gradient(circle_at_top,_#fef3c7,_transparent_28%),linear-gradient(180deg,_#fffdf8_0%,_#f8fafc_48%,_#eef2ff_100%)]">
        <div className="rounded-[28px] border border-white/70 bg-white/85 px-8 py-6 text-lg font-semibold text-slate-700 shadow-xl shadow-slate-200/70 backdrop-blur">
          Загрузка...
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[radial-gradient(circle_at_top,_#fde68a,_transparent_26%),linear-gradient(180deg,_#fffdf8_0%,_#f8fafc_44%,_#e0e7ff_100%)] px-4">
      <div className="grid w-full max-w-5xl overflow-hidden rounded-[32px] border border-white/70 bg-white/75 shadow-2xl shadow-slate-200/70 backdrop-blur lg:grid-cols-[1.1fr_0.9fr]">
        <div className="hidden bg-[linear-gradient(145deg,_#0f172a,_#1e293b_55%,_#334155)] p-10 text-white lg:block">
          <div className="text-xs font-semibold uppercase tracking-[0.32em] text-slate-300">Deti Admin</div>
          <h1 className="mt-6 max-w-sm text-4xl font-black leading-tight">
            Удобная панель для управления категориями, животными и медиа
          </h1>
          <p className="mt-4 max-w-md text-sm leading-6 text-slate-300">
            Редактируй каталог, обновляй герои, управляй иконками и быстро наполняй приложение новым контентом.
          </p>
          <div className="mt-10 grid gap-4">
            {[
              'Категории и порядок показа',
              'Животные, аудио, видео и иконки',
              'Онбординг, акции и родительский контроль',
            ].map((item) => (
              <div key={item} className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm font-medium">
                {item}
              </div>
            ))}
          </div>
        </div>

        <div className="p-8 sm:p-10">
          <div className="mx-auto max-w-md">
            <div className="text-xs font-semibold uppercase tracking-[0.28em] text-slate-400">Secure access</div>
            <h2 className="mt-3 text-3xl font-black tracking-tight text-slate-900">Вход в админку</h2>
            <p className="mt-2 text-sm text-slate-500">Используй свои данные для входа и управления контентом приложения.</p>
          </div>

          <div className="mx-auto mt-8 max-w-md space-y-5">
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-700">Логин</label>
            <input
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              autoComplete="username"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-700">Пароль</label>
            <input
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-200/60"
              type="password"
              autoComplete="current-password"
            />
          </div>
          </div>

          <div className="mx-auto mt-8 max-w-md">
            <button
              onClick={handleSignIn}
              disabled={submitting}
              className="w-full rounded-2xl bg-slate-900 px-4 py-3.5 text-base font-bold text-white transition hover:bg-slate-700 disabled:bg-slate-400"
            >
              {submitting ? 'Входим...' : 'Войти'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
