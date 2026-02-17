# Настройка Flutter приложения

## Что уже сделано

✅ Создан Flutter проект с полной структурой  
✅ Настроены все зависимости (Firebase, StoreKit, Lottie, Audio)  
✅ Созданы модели данных (Category, Animal, Offer)  
✅ Реализованы сервисы (Firebase, Purchase, Audio)  
✅ Созданы провайдеры для state management  
✅ Реализованы все основные экраны:
   - Онбординг
   - Категории животных
   - Список животных в категории
   - Детальная страница животного с анимацией и звуком
   - Профиль

## Следующие шаги

### 1. Настройка Firebase

#### Для iOS:
1. Откройте Firebase Console
2. Скачайте `GoogleService-Info.plist`
3. Добавьте файл в `ios/Runner/GoogleService-Info.plist`
4. Откройте проект в Xcode: `ios/Runner.xcworkspace`
5. Убедитесь, что файл добавлен в проект

#### Для Android (опционально):
1. Скачайте `google-services.json`
2. Добавьте в `android/app/google-services.json`
3. Добавьте в `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
4. В `android/app/build.gradle` добавьте в конец:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### 2. Запуск на Windows (для разработки)

```bash
cd mobile
flutter run
```

Приложение запустится в Chrome или другом доступном эмуляторе.

### 3. Запуск на Mac (для iOS)

```bash
cd mobile
flutter run -d ios
```

Или откройте в Xcode:
```bash
open ios/Runner.xcworkspace
```

### 4. Настройка StoreKit 2 (для платных категорий)

1. Откройте App Store Connect
2. Создайте In-App Purchase продукты
3. Используйте Product ID в админ панели при создании категорий

### 5. Добавление медиа-файлов

Загрузите в Firebase Storage:
- Иконки категорий → `icons/`
- Фоновые изображения → `backgrounds/`
- Превью животных → `previews/`
- Звуки → `sounds/`
- Lottie анимации → `animations/`

## Структура проекта

```
mobile/
├── lib/
│   ├── models/          # Модели данных
│   ├── services/        # Бизнес-логика
│   ├── providers/       # State management
│   ├── screens/         # Экраны приложения
│   ├── widgets/         # Переиспользуемые виджеты
│   └── utils/           # Утилиты
└── assets/              # Ресурсы (изображения, шрифты)
```

## Функции приложения

- 🎨 Красивый онбординг с анимациями
- 📁 Категории животных с сеткой карточек
- 🐾 Детальные страницы с Lottie анимациями
- 🔊 Воспроизведение звуков животных
- 💰 Платные категории через StoreKit 2
- 🌍 Локализация (RU/EN)
- 🔄 Автоматическая синхронизация с Firebase

## Тестирование

Приложение готово к запуску! После добавления Firebase конфигурации все функции будут работать.
