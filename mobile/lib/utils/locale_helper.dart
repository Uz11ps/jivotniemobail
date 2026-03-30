import 'package:flutter/material.dart';

class LocaleHelper {
  static String getCurrentLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ru') return 'ru';
    return 'en';
  }

  static String getLocalizedString(
    Map<String, String> localized,
    BuildContext context,
  ) {
    final locale = getCurrentLocale(context);
    return localized[locale] ?? localized['ru'] ?? '';
  }
}
