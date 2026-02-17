# Дети и Животные - Flutter iOS приложение

Приложение для детей с категориями животных, анимациями и звуками.

## Структура проекта

```
lib/
├── models/          # Модели данных (Category, Animal, Offer)
├── services/        # Сервисы (Firebase, Purchase, Audio)
├── providers/       # State management (Categories, Animals, Purchase)
├── screens/         # Экраны приложения
├── widgets/         # Переиспользуемые виджеты
└── utils/           # Утилиты (роутер, локализация)
```

## Настройка Firebase

### iOS

1. Скачайте `GoogleService-Info.plist` из Firebase Console
2. Добавьте файл в `ios/Runner/GoogleService-Info.plist`
3. Откройте `ios/Runner.xcworkspace` в Xcode
4. Убедитесь, что файл добавлен в проект

### Android

1. Скачайте `google-services.json` из Firebase Console
2. Добавьте файл в `android/app/google-services.json`
3. Убедитесь, что в `android/build.gradle` добавлен плагин:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
4. В `android/app/build.gradle` добавьте в конец:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Запуск приложения

### На Windows (для разработки)

```bash
cd mobile
flutter run
```

### На Mac (для iOS)

```bash
cd mobile
flutter run -d ios
```

## Функции

- ✅ Онбординг с красивыми экранами
- ✅ Категории животных с сеткой карточек
- ✅ Детальные страницы с анимациями Lottie
- ✅ Воспроизведение звуков животных
- ✅ Платные категории через StoreKit 2
- ✅ Локализация (RU/EN)
- ✅ Интеграция с Firebase (Firestore, Storage)

## Следующие шаги

1. Добавьте файлы конфигурации Firebase
2. Настройте StoreKit 2 в App Store Connect
3. Добавьте медиа-файлы (изображения, звуки, анимации) в Firebase Storage
4. Протестируйте на реальном устройстве iOS
