'use client';

import { useState } from 'react';
import { uploadFileWithMeta, getFileUrlFromPathOrUrl } from '@/lib/storage';

export type UploadedMeta = {
  path: string;
  url: string;
};

interface StorageFileUploadProps {
  path: string;
  onUploaded: (meta: UploadedMeta) => void;
  accept?: string;
  label?: string;
  value?: string; // Firestore value: path OR legacy url
}

export function StorageFileUpload({
  path,
  onUploaded,
  accept,
  label,
  value,
}: StorageFileUploadProps) {
  const [uploading, setUploading] = useState(false);
  const previewUrl = value ? getFileUrlFromPathOrUrl(value) : null;

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const meta = await uploadFileWithMeta(path, file);
      onUploaded(meta);
    } catch (error) {
      console.error('Ошибка загрузки файла:', error);
      alert('Не удалось загрузить файл');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="rounded-3xl border border-slate-200 bg-slate-50/80 p-4">
      {label && <label className="mb-2 block text-sm font-semibold text-slate-800">{label}</label>}
      <input
        type="file"
        accept={accept}
        onChange={handleFileChange}
        disabled={uploading}
        className="block w-full text-sm text-slate-500 file:mr-4 file:rounded-2xl file:border-0 file:bg-slate-900 file:px-4 file:py-2.5 file:text-sm file:font-semibold file:text-white hover:file:bg-slate-700"
      />
      <div className="mt-2 text-xs text-slate-400">
        Поддерживается загрузка изображений, видео и аудио. Новый файл сразу заменит текущее значение.
      </div>
      {uploading && <p className="mt-2 text-sm font-medium text-slate-500">Загрузка...</p>}
      {previewUrl && (
        <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200 bg-white p-3">
          {previewUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
            <img src={previewUrl} alt="Preview" className="max-h-40 max-w-xs rounded-2xl object-contain" />
          ) : previewUrl.match(/\.(mp4|webm|mov)$/i) ? (
            <video src={previewUrl} controls className="max-h-40 max-w-xs rounded-2xl" />
          ) : previewUrl.match(/\.(mp3|wav|m4a|aac|ogg)$/i) ? (
            <audio src={previewUrl} controls className="w-full" />
          ) : (
            <a href={previewUrl} target="_blank" rel="noopener noreferrer" className="font-semibold text-blue-600">
              Просмотр файла
            </a>
          )}
        </div>
      )}
    </div>
  );
}

