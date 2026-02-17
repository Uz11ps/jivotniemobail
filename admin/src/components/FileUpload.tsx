'use client';

import { useState } from 'react';
import { uploadFile } from '@/lib/storage';

interface FileUploadProps {
  path: string;
  onUploaded: (url: string) => void;
  accept?: string;
  label?: string;
}

export function FileUpload({ path, onUploaded, accept, label }: FileUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState<string | null>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const url = await uploadFile(path, file);
      setPreview(url);
      onUploaded(url);
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
      {preview && (
        <div className="mt-2">
          {preview.match(/\.(jpg|jpeg|png|gif)$/i) ? (
            <img src={preview} alt="Preview" className="max-w-xs rounded" />
          ) : (
            <a href={preview} target="_blank" rel="noopener noreferrer" className="text-blue-600">
              Просмотр файла
            </a>
          )}
        </div>
      )}
    </div>
  );
}
