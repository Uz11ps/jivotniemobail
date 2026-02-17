import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _prefsKey = 'app_locale';
  static const List<String> supportedCodes = ['ru', 'en'];

  Locale _locale = const Locale('ru', 'RU');
  bool _isLoaded = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedCodes.contains(saved)) {
      _locale = saved == 'en' ? const Locale('en', 'US') : const Locale('ru', 'RU');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (!supportedCodes.contains(code)) return;
    final next = code == 'en' ? const Locale('en', 'US') : const Locale('ru', 'RU');
    if (next == _locale) return;
    _locale = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }
}

