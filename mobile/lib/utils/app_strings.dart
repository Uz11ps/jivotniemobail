import 'package:flutter/material.dart';
import 'locale_helper.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _v = {
    'common.back': {'ru': 'Назад', 'en': 'Back'},
    'common.save': {'ru': 'Сохранить', 'en': 'Save'},
    'common.cancel': {'ru': 'Отмена', 'en': 'Cancel'},
    'common.retry': {'ru': 'Повторить', 'en': 'Retry'},
    'common.loadingError': {'ru': 'Ошибка загрузки', 'en': 'Loading error'},

    'language.title': {'ru': 'Выберите язык', 'en': 'Choose language'},
    'language.russian': {'ru': 'Русский', 'en': 'Russian'},
    'language.english': {'ru': 'English', 'en': 'English'},

    'onboarding.subtitle1': {'ru': 'Изучаем животных играя', 'en': 'Learn animals through play'},
    'onboarding.subtitle2': {'ru': 'Звуки и анимации животных', 'en': 'Animal sounds and animations'},
    'onboarding.subtitle3': {'ru': 'Новые категории из админки', 'en': 'New categories from admin'},
    'onboarding.continue': {'ru': 'Продолжить', 'en': 'Continue'},

    'animals.titleFallback': {'ru': 'Животные', 'en': 'Animals'},
    'animals.notFound': {'ru': 'Животные не найдены', 'en': 'No animals found'},
    'categories.empty': {'ru': 'Категории не найдены.\nДобавьте их в админке.', 'en': 'No categories found.\nAdd them in admin panel.'},
    'categories.lockedTitle': {'ru': 'Категория закрыта', 'en': 'Category is locked'},
    'categories.lockedText': {
      'ru': 'Эта категория платная. Подтвердите покупку в App Store.',
      'en': 'This category is paid. Confirm purchase in App Store.',
    },
    'common.ok': {'ru': 'Ок', 'en': 'OK'},
    'animal.notFound': {'ru': 'Животное не найдено', 'en': 'Animal not found'},
    'animal.title': {'ru': 'Животное', 'en': 'Animal'},

    'order.title': {'ru': 'Порядок', 'en': 'Order'},
    'order.price': {'ru': '69 ₽', 'en': '\$0.99'},

    'purchases.title': {'ru': 'Мои покупки', 'en': 'My purchases'},
    'purchases.emptyTitle': {'ru': 'Еще ничего не купили', 'en': 'No purchases yet'},
    'purchases.emptySubtitle': {
      'ru': 'Купите дополнительные\nпаки и киндер будет кайфовать',
      'en': 'Buy extra packs\nand keep learning with fun',
    },
    'purchases.buyPacks': {'ru': 'Купить паки', 'en': 'Buy packs'},

    'rate.text': {'ru': 'Перекидывает\nсразу писать отзыв', 'en': 'Redirects directly\nto write a review'},

    'profile.title': {'ru': 'Профиль', 'en': 'Profile'},
    'profile.favoriteCategories': {'ru': 'Любимые категории', 'en': 'Favorite categories'},
    'profile.favoriteWords': {'ru': 'Любимые слова', 'en': 'Favorite words'},
    'profile.noData': {
      'ru': 'Пока нет данных.\nИграйте в приложение\nи они появятся.',
      'en': 'No data yet.\nUse the app\nand stats will appear.',
    },
    'profile.settings': {'ru': 'Настройки', 'en': 'Settings'},
    'profile.extra': {'ru': 'Дополнительно', 'en': 'Additional'},
    'profile.categoriesOrder': {'ru': 'Порядок категорий', 'en': 'Category order'},
    'profile.notifications': {'ru': 'Уведомления', 'en': 'Notifications'},
    'profile.soundEffects': {'ru': 'Звуковые эффекты', 'en': 'Sound effects'},
    'profile.language': {'ru': 'Выбор языка', 'en': 'Language'},
    'profile.myPurchases': {'ru': 'Мои покупки', 'en': 'My purchases'},
    'profile.rateApp': {'ru': 'Оценить приложение', 'en': 'Rate app'},
    'profile.share': {'ru': 'Поделиться', 'en': 'Share'},
    'profile.deviceId': {'ru': 'ID устройства', 'en': 'Device ID'},
    'profile.shareSoon': {'ru': 'Поделиться: скоро добавим', 'en': 'Share: coming soon'},
    'profile.resetOnboarding': {'ru': 'Сбросить онбординг', 'en': 'Reset onboarding'},
    'profile.langRu': {'ru': 'Русский', 'en': 'Russian'},
    'profile.parentalTitle': {'ru': 'Родительский контроль', 'en': 'Parental control'},
    'profile.parentalLoadError': {
      'ru': 'Не удалось загрузить тест родительского контроля',
      'en': 'Failed to load parental control test',
    },
    'profile.parentalNoTests': {
      'ru': 'Добавьте тесты родительского контроля в админке',
      'en': 'Add parental control tests in admin panel',
    },
    'profile.deviceIdCopied': {'ru': 'ID устройства скопирован', 'en': 'Device ID copied'},
    'profile.close': {'ru': 'Закрыть', 'en': 'Close'},
    'profile.copy': {'ru': 'Скопировать', 'en': 'Copy'},
  };

  static String t(BuildContext context, String key) {
    final locale = LocaleHelper.getCurrentLocale(context);
    final row = _v[key];
    if (row == null) return key;
    return row[locale] ?? row['ru'] ?? key;
  }
}

