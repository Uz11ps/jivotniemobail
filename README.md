# Дети и Животные - iOS приложение с админ-панелью

Приложение для детей с категориями животных, анимациями и звуками. Полностью управляемое через web-админку.

## Структура проекта

- `ios/` - iOS приложение на SwiftUI
- `admin/` - Web админ-панель на Next.js
- `firebase/` - Firebase конфигурация и Cloud Functions
- `docs/` - Документация

## Быстрый старт

См. [docs/SETUP.md](docs/SETUP.md) для подробной инструкции по настройке.

### iOS приложение
```bash
cd ios/DetiZhivotnieApp
open DetiZhivotnieApp.xcodeproj
```

### Админ-панель
```bash
cd admin
npm install
npm run dev
```

### Firebase
```bash
cd firebase
npm install
firebase login
firebase use --add
firebase deploy
```

## Технологии

- **iOS**: SwiftUI, StoreKit 2, Firebase SDK, Lottie
- **Admin**: Next.js 14, React, Firebase Admin SDK, Tailwind CSS
- **Backend**: Firebase (Firestore, Storage, Auth, Functions)

## Документация

- [Настройка проекта](docs/SETUP.md)
- [Руководство для заказчика](docs/ADMIN_GUIDE.md)
- [Настройка IAP в App Store Connect](docs/APP_STORE_CONNECT.md)

## Основные возможности

### iOS приложение
- Онбординг с свайпом
- Категории животных с сеткой карточек
- Детальные страницы с анимациями и звуками
- Платные категории через StoreKit 2
- Родительский контроль
- Профиль с настройками и статистикой
- Локализация (RU/EN)

### Админ-панель
- Управление категориями и животными
- Загрузка медиа-файлов
- Управление офферами
- Аналитический дашборд
- Управление ролями пользователей
