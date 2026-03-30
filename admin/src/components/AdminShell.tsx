'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  BarChart3,
  FolderKanban,
  GalleryVerticalEnd,
  LogOut,
  PawPrint,
  ShieldCheck,
  Sparkles,
  Ticket,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

type AdminShellProps = {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
  children: React.ReactNode;
};

const navItems = [
  { href: '/dashboard', label: 'Главная', icon: Sparkles },
  { href: '/categories', label: 'Категории', icon: FolderKanban },
  { href: '/offers', label: 'Офферы', icon: Ticket },
  { href: '/analytics', label: 'Аналитика', icon: BarChart3 },
  { href: '/parental-tests', label: 'Тесты', icon: ShieldCheck },
  { href: '/onboarding', label: 'Онбординг', icon: GalleryVerticalEnd },
];

function NavLink({
  href,
  label,
  icon: Icon,
  active,
}: {
  href: string;
  label: string;
  icon: typeof Sparkles;
  active: boolean;
}) {
  return (
    <Link
      href={href}
      className={[
        'flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold transition-all',
        active
          ? 'bg-slate-900 text-white shadow-lg shadow-slate-300/60'
          : 'text-slate-600 hover:bg-white hover:text-slate-900',
      ].join(' ')}
    >
      <Icon className="h-4 w-4" />
      <span>{label}</span>
    </Link>
  );
}

export function AdminShell({ title, subtitle, action, children }: AdminShellProps) {
  const pathname = usePathname();
  const { user, signOut } = useAuth();

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,_#fef3c7,_transparent_28%),linear-gradient(180deg,_#fffdf8_0%,_#f8fafc_48%,_#eef2ff_100%)]">
      <div className="mx-auto flex min-h-screen max-w-7xl gap-6 px-4 py-4 sm:px-6 lg:px-8">
        <aside className="hidden w-72 shrink-0 lg:block">
          <div className="sticky top-4 overflow-hidden rounded-[28px] border border-white/70 bg-white/85 p-5 shadow-xl shadow-slate-200/70 backdrop-blur">
            <div className="mb-6 flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-900 text-white">
                <PawPrint className="h-6 w-6" />
              </div>
              <div>
                <div className="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Deti Admin
                </div>
                <div className="text-lg font-bold text-slate-900">Панель контента</div>
              </div>
            </div>

            <div className="mb-6 rounded-3xl bg-gradient-to-br from-amber-100 via-white to-sky-100 p-4">
              <div className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
                Авторизован
              </div>
              <div className="mt-2 text-lg font-bold text-slate-900">{user?.username || 'admin'}</div>
              <div className="mt-1 text-sm text-slate-500">Управление категориями, животными и медиа</div>
            </div>

            <nav className="space-y-2">
              {navItems.map((item) => (
                <NavLink
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  icon={item.icon}
                  active={pathname === item.href || pathname.startsWith(`${item.href}/`)}
                />
              ))}
            </nav>

            <button
              onClick={signOut}
              className="mt-6 flex w-full items-center justify-center gap-2 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600 transition hover:border-slate-300 hover:bg-slate-50 hover:text-slate-900"
            >
              <LogOut className="h-4 w-4" />
              Выйти
            </button>
          </div>
        </aside>

        <div className="min-w-0 flex-1">
          <div className="overflow-hidden rounded-[32px] border border-white/70 bg-white/80 shadow-xl shadow-slate-200/70 backdrop-blur">
            <div className="border-b border-slate-100 px-5 py-5 sm:px-8">
              <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div>
                  <div className="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Admin workspace
                  </div>
                  <h1 className="mt-2 text-3xl font-black tracking-tight text-slate-900">{title}</h1>
                  {subtitle ? <p className="mt-2 max-w-2xl text-sm text-slate-500">{subtitle}</p> : null}
                </div>
                {action ? <div className="shrink-0">{action}</div> : null}
              </div>
            </div>
            <div className="px-5 py-5 sm:px-8 sm:py-8">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
