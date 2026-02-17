# Инструкция по настройке проекта

## Предварительные требования

- Node.js 18+
- Xcode 15+
- Firebase CLI
- CocoaPods (для iOS)

## Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте iOS приложение:
   - Bundle ID: `com.yourcompany.detizhivotnie`
   - Скачайте `GoogleService-Info.plist` и добавьте в iOS проект
3. Включите следующие сервисы:
   - Firestore Database
   - Storage
   - Authentication (Google provider)
   - Functions
   - App Check (опционально)

4. Настройте Firestore:
   ```bash
   cd firebase
   firebase init
   firebase deploy --only firestore:rules,firestore:indexes
   ```

5. Настройте Storage rules:
   ```bash
   firebase deploy --only storage:rules
   ```

6. Разверните Cloud Functions:
   ```bash
   cd firebase
   npm install
   npm run deploy
   ```

## Настройка админ-панели

1. Перейдите в папку `admin`:
   ```bash
   cd admin
   npm install
   ```

2. Создайте файл `.env.local` на основе `.env.example`:
   ```bash
   cp .env.example .env.local
   ```

3. Заполните переменные окружения из Firebase Console:
   - Project Settings → General → Your apps → Web app

4. Запустите админ-панель:
   ```bash
   npm run dev
   ```

5. Откройте http://localhost:3000

6. Войдите через Google и назначьте себе роль admin через Firebase Console:
   - Authentication → Users → выберите пользователя
   - Custom claims → добавьте `{ "role": "admin" }`

## Настройка iOS приложения

1. Откройте проект в Xcode:
   ```bash
   cd ios/DetiZhivotnieApp
   open DetiZhivotnieApp.xcodeproj
   ```

2. Добавьте `GoogleService-Info.plist` в проект

3. Установите зависимости через Swift Package Manager:
   - File → Add Packages
   - Добавьте Firebase iOS SDK
   - Добавьте Lottie iOS

4. Настройте App Store Connect:
   - Создайте приложение
   - Настройте In-App Purchases для каждой платной категории
   - Product ID должен совпадать с `iapProductId` в админке

5. Настройте Capabilities:
   - In-App Purchase
   - Push Notifications (опционально)

6. Запустите приложение на симуляторе или устройстве

## Первоначальная настройка данных

1. Войдите в админ-панель
2. Создайте первую категорию (например, "Домашние животные")
3. Добавьте животных в категорию
4. Загрузите медиа-файлы (изображения, звуки, анимации)
5. Настройте офферы (опционально)

## Тестирование

### Тестирование админ-панели
1. Проверьте создание/редактирование категорий
2. Проверьте загрузку медиа-файлов
3. Проверьте изменение порядка через drag&drop

### Тестирование iOS приложения
1. Проверьте онбординг
2. Проверьте загрузку категорий из Firestore
3. Проверьте отображение животных
4. Проверьте воспроизведение звуков
5. Проверьте покупки (используйте sandbox аккаунт)

## Развертывание

### Админ-панель
```bash
cd admin
npm run build
# Разверните на Vercel или Firebase Hosting
```

### iOS приложение
1. Настройте сертификаты в Xcode
2. Archive → Distribute App
3. Загрузите в App Store Connect

### Firebase Functions
```bash
cd firebase
npm run deploy
```

## Поддержка

При возникновении проблем:
1. Проверьте логи в Firebase Console
2. Проверьте консоль браузера (для админки)
3. Проверьте Xcode console (для iOS)
4. Убедитесь, что все переменные окружения настроены правильно
