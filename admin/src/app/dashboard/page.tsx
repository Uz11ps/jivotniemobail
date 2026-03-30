'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { AdminShell } from '@/components/AdminShell';
import Link from 'next/link';
import { BarChart3, FolderKanban, GalleryVerticalEnd, PawPrint, ShieldCheck, Ticket } from 'lucide-react';

function DashboardContent() {
  const cards = [
    {
      href: '/categories',
      title: 'Категории',
      description: 'Создание категорий, цвета фона, hero-блоки и таб-иконки.',
      icon: FolderKanban,
    },
    {
      href: '/categories',
      title: 'Животные',
      description: 'Быстрый переход к спискам животных внутри каждой категории.',
      icon: PawPrint,
    },
    {
      href: '/offers',
      title: 'Офферы',
      description: 'Управление paywall, карточками покупки и текстами предложений.',
      icon: Ticket,
    },
    {
      href: '/analytics',
      title: 'Аналитика',
      description: 'Переход к графикам и событиям использования приложения.',
      icon: BarChart3,
    },
    {
      href: '/parental-tests',
      title: 'Родительский контроль',
      description: 'Настройка математических тестов перед входом в кабинет.',
      icon: ShieldCheck,
    },
    {
      href: '/onboarding',
      title: 'Онбординг',
      description: 'Редактирование стартовых экранов, видео и фоновых цветов.',
      icon: GalleryVerticalEnd,
    },
  ];

  return (
    <AdminShell
      title="Панель управления"
      subtitle="Главная точка входа для работы с категориями, животными, медиа-файлами, онбордингом и промо-блоками."
    >
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: 'Основной каталог', value: '6 разделов', hint: 'категории, hero и навбар' },
          { label: 'Контент животных', value: '60+ карточек', hint: 'иконки, видео и аудио' },
          { label: 'Управление приложением', value: '3 зоны', hint: 'онбординг, офферы, тесты' },
        ].map((item) => (
          <div key={item.label} className="rounded-[28px] border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-5">
            <div className="text-sm font-semibold text-slate-500">{item.label}</div>
            <div className="mt-3 text-3xl font-black tracking-tight text-slate-900">{item.value}</div>
            <div className="mt-2 text-sm text-slate-500">{item.hint}</div>
          </div>
        ))}
      </div>

      <div className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        {cards.map(({ href, title, description, icon: Icon }) => (
          <Link
            key={href + title}
            href={href}
            className="group rounded-[28px] border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-lg"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-900 text-white transition group-hover:bg-slate-700">
              <Icon className="h-5 w-5" />
            </div>
            <h2 className="mt-5 text-xl font-black tracking-tight text-slate-900">{title}</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p>
            <div className="mt-5 text-sm font-semibold text-slate-900">Открыть раздел</div>
          </Link>
        ))}
      </div>
    </AdminShell>
  );
}

export default function DashboardPage() {
  return (
    <ProtectedRoute>
      <DashboardContent />
    </ProtectedRoute>
  );
}
