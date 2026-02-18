'use client';

import { ProtectedRoute } from '@/components/ProtectedRoute';
import { useEffect, useState } from 'react';
import { StorageFileUpload } from '@/components/StorageFileUpload';
import { getFileUrlFromPathOrUrl } from '@/lib/storage';

type Slide = {
  id?: string;
  order: number;
  isActive: boolean;
  title: { ru: string; en: string };
  subtitle: { ru: string; en: string };
  imageAssetPath: string;
  backgroundColorHex?: string;
};

const DEFAULT_SLIDES: Slide[] = [
  {
    id: 'slide_1',
    order: 0,
    isActive: true,
    title: { ru: "LET'S EXPLORE!", en: "LET'S EXPLORE!" },
    subtitle: { ru: 'Изучаем животных играя', en: 'Learn animals through play' },
    imageAssetPath: '',
    backgroundColorHex: '#F0F2F5',
  },
  {
    id: 'slide_2',
    order: 1,
    isActive: true,
    title: { ru: "LET'S LISTEN!", en: "LET'S LISTEN!" },
    subtitle: { ru: 'Звуки и анимации животных', en: 'Animal sounds and animations' },
    imageAssetPath: '',
    backgroundColorHex: '#F0F2F5',
  },
  {
    id: 'slide_3',
    order: 2,
    isActive: true,
    title: { ru: "LET'S LEARN!", en: "LET'S LEARN!" },
    subtitle: { ru: 'Новые категории из админки', en: 'New categories from admin' },
    imageAssetPath: '',
    backgroundColorHex: '#F0F2F5',
  },
];

function OnboardingContent() {
  const [slides, setSlides] = useState<Slide[]>(DEFAULT_SLIDES);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const res = await fetch('/api/admin/onboarding');
        const json = await res.json();
        if (!mounted) return;
        if (json?.ok && Array.isArray(json.slides) && json.slides.length > 0) {
          const sorted = [...json.slides].sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
          setSlides(sorted);
        }
      } catch (_) {
        // keep defaults
      } finally {
        if (mounted) setLoading(false);
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  const updateSlide = (idx: number, patch: Partial<Slide>) => {
    setSlides((prev) =>
      prev.map((s, i) => (i === idx ? { ...s, ...patch } : s))
    );
  };

  const save = async () => {
    setSaving(true);
    try {
      const payload = slides.map((s, i) => ({ ...s, order: i }));
      const res = await fetch('/api/admin/onboarding', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slides: payload }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok || !json?.ok) {
        throw new Error('save_failed');
      }
      alert('Сохранено');
    } catch (e) {
      console.error(e);
      alert('Не удалось сохранить онбординг');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="p-8">Загрузка...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">Онбординг (3 первых экрана)</h1>
          <button
            onClick={save}
            disabled={saving}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {saving ? 'Сохраняю...' : 'Сохранить'}
          </button>
        </div>

        <div className="space-y-5">
          {slides.map((slide, idx) => (
            <div key={slide.id ?? idx} className="bg-white rounded-lg shadow p-5">
              <h2 className="text-lg font-semibold mb-4">Слайд {idx + 1}</h2>
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Title (RU)</label>
                  <input
                    value={slide.title?.ru ?? ''}
                    onChange={(e) =>
                      updateSlide(idx, {
                        title: { ...(slide.title ?? { ru: '', en: '' }), ru: e.target.value },
                      })
                    }
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Title (EN)</label>
                  <input
                    value={slide.title?.en ?? ''}
                    onChange={(e) =>
                      updateSlide(idx, {
                        title: { ...(slide.title ?? { ru: '', en: '' }), en: e.target.value },
                      })
                    }
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Subtitle (RU)</label>
                  <input
                    value={slide.subtitle?.ru ?? ''}
                    onChange={(e) =>
                      updateSlide(idx, {
                        subtitle: { ...(slide.subtitle ?? { ru: '', en: '' }), ru: e.target.value },
                      })
                    }
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Subtitle (EN)</label>
                  <input
                    value={slide.subtitle?.en ?? ''}
                    onChange={(e) =>
                      updateSlide(idx, {
                        subtitle: { ...(slide.subtitle ?? { ru: '', en: '' }), en: e.target.value },
                      })
                    }
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
              </div>

              <div className="mb-4">
                <StorageFileUpload
                  path={`onboarding/${Date.now()}-${idx + 1}.png`}
                  value={slide.imageAssetPath}
                  onUploaded={(meta) => updateSlide(idx, { imageAssetPath: meta.url })}
                  accept="image/*"
                  label="Картинка слайда"
                />
                {slide.imageAssetPath && (
                  <img
                    src={getFileUrlFromPathOrUrl(slide.imageAssetPath)}
                    alt={`slide-${idx + 1}`}
                    className="mt-2 h-40 w-auto rounded object-contain bg-slate-50"
                  />
                )}
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">Цвет фона</label>
                <input
                  type="color"
                  value={slide.backgroundColorHex || '#F0F2F5'}
                  onChange={(e) => updateSlide(idx, { backgroundColorHex: e.target.value })}
                  className="h-10 w-20 p-1 border rounded"
                />
              </div>

              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={slide.isActive ?? true}
                  onChange={(e) => updateSlide(idx, { isActive: e.target.checked })}
                />
                <span>Слайд активен</span>
              </label>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function OnboardingPage() {
  return (
    <ProtectedRoute>
      <OnboardingContent />
    </ProtectedRoute>
  );
}
