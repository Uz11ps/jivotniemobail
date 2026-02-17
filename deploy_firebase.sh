#!/bin/bash
# Скрипт для деплоя Firebase Functions и правил

set -e

echo "🚀 Деплой Firebase..."

cd firebase

# Проверка установки Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI не установлен. Установите: npm install -g firebase-tools"
    exit 1
fi

# Проверка авторизации
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Требуется авторизация Firebase..."
    firebase login
fi

# Выбор проекта (если не выбран)
if [ ! -f ".firebaserc" ]; then
    echo "📋 Выберите Firebase проект..."
    firebase use --add
fi

# Установка зависимостей
echo "📦 Установка зависимостей..."
npm install

# Сборка TypeScript
echo "🔨 Сборка TypeScript..."
npm run build

# Деплой правил Firestore
echo "📝 Деплой правил Firestore..."
firebase deploy --only firestore:rules

# Деплой индексов Firestore
echo "📇 Деплой индексов Firestore..."
firebase deploy --only firestore:indexes

# Деплой правил Storage
echo "💾 Деплой правил Storage..."
firebase deploy --only storage:rules

# Деплой Functions
echo "⚡ Деплой Cloud Functions..."
firebase deploy --only functions

echo "✅ Деплой Firebase завершён!"
