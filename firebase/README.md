# Firebase конфигурация

## Структура данных Firestore

### appConfig/main
```json
{
  "minAppVersion": "1.0.0",
  "defaultLanguage": "ru",
  "onboarding": [
    {
      "title": { "ru": "Добро пожаловать", "en": "Welcome" },
      "subtitle": { "ru": "Изучайте животных", "en": "Learn animals" },
      "illustrationAsset": "onboarding/welcome.png"
    }
  ],
  "parentalGate": {
    "difficulty": "easy",
    "optionsCount": 3
  }
}
```

### categories/{categoryId}
```json
{
  "order": 0,
  "isVisible": true,
  "isPaid": false,
  "iapProductId": null,
  "title": {
    "ru": "Домашние животные",
    "en": "Domestic animals"
  },
  "tabIconAssetPath": "categories/pets-icon.png",
  "gridCardStyle": {
    "backgroundColor": "#F5E6D3",
    "cornerRadius": 20
  }
}
```

### categories/{categoryId}/animals/{animalId}
```json
{
  "order": 0,
  "isVisible": true,
  "name": {
    "ru": "Собака",
    "en": "Dog"
  },
  "bgAssetPath": "animals/dog-bg.png",
  "previewAssetPath": "animals/dog-preview.png",
  "voiceAssetPath": {
    "ru": "animals/dog-voice-ru.mp3",
    "en": "animals/dog-voice-en.mp3"
  },
  "soundAssetPath": "animals/dog-sound.mp3",
  "animationAssetPath": "animals/dog-animation.lottie"
}
```

### offers/{offerId}
```json
{
  "isActive": true,
  "title": {
    "ru": "SPECIAL OFFER",
    "en": "SPECIAL OFFER"
  },
  "heroAssets": [
    "offers/star.png",
    "offers/rocket.png",
    "offers/gift.png"
  ],
  "items": [
    {
      "label": {
        "ru": "Все категории",
        "en": "All categories"
      },
      "productId": "com.app.all_categories",
      "badge": {
        "ru": "Выгодно",
        "en": "Best value"
      }
    }
  ],
  "primaryProductId": "com.app.all_categories"
}
```

## Развертывание

```bash
# Установка зависимостей
npm install

# Локальный запуск эмуляторов
npm run serve

# Развертывание функций
npm run deploy

# Развертывание правил Firestore
firebase deploy --only firestore:rules

# Развертывание правил Storage
firebase deploy --only storage:rules
```

## Настройка App Check

1. В Firebase Console включите App Check
2. Для iOS добавьте App Attest provider
3. Обновите токен в iOS приложении
