import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  late String _selected;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _selected = context.read<LocaleProvider>().languageCode;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final title = localeCode == 'ru' ? 'Язык' : 'Language';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F8FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.black, size: 24),
                    ),
                  ),
                  const Spacer(),
                  Text(title,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 22),
              _LanguageTile(
                flag: '🇺🇸',
                title: 'English',
                selected: _selected == 'en',
                onTap: () async {
                  setState(() => _selected = 'en');
                  await context.read<LocaleProvider>().setLanguageCode('en');
                },
              ),
              const SizedBox(height: 10),
              _LanguageTile(
                flag: '🇷🇺',
                title: 'Русский',
                selected: _selected == 'ru',
                onTap: () async {
                  setState(() => _selected = 'ru');
                  await context.read<LocaleProvider>().setLanguageCode('ru');
                },
              ),
              const SizedBox(height: 10),
              _LanguageTile(
                flag: '🇪🇸',
                title: 'Español',
                selected: _selected == 'es',
                onTap: () async {
                  setState(() => _selected = 'es');
                  await context.read<LocaleProvider>().setLanguageCode('es');
                },
              ),
              const SizedBox(height: 10),
              _LanguageTile(
                flag: '🇮🇳',
                title: 'भारतीय',
                selected: _selected == 'hi',
                onTap: () async {
                  setState(() => _selected = 'hi');
                  await context.read<LocaleProvider>().setLanguageCode('hi');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF1273EA) : const Color(0xFFC9CBD2),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
