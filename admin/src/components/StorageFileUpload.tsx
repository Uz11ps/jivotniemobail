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
    <div>
      {label && <label className="block text-sm font-medium mb-2">{label}</label>}
      <input
        type="file"
        accept={accept}
        onChange={handleFileChange}
        disabled={uploading}
        className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
      />
      {uploading && <p className="text-sm text-gray-500 mt-1">Загрузка...</p>}
      {previewUrl && (
        <div className="mt-2">
          {previewUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
            <img src={previewUrl} alt="Preview" className="max-w-xs rounded" />
          ) : previewUrl.match(/\.(mp4|webm|mov)$/i) ? (
            <video src={previewUrl} controls className="max-w-xs rounded" />
          ) : previewUrl.match(/\.(mp3|wav|m4a|aac|ogg)$/i) ? (
            <audio src={previewUrl} controls className="w-full" />
          ) : (
            <a href={previewUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600">
              Просмотр файла
            </a>
          )}
        </div>
      )}
    </div>
  );
}

