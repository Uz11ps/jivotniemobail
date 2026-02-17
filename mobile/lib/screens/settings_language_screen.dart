import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_strings.dart';

class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  late String _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected = context.read<LocaleProvider>().languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
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
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_left, color: Color(0xFF1273EA), size: 26),
                        Text(
                          AppStrings.t(context, 'common.back'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: Color(0xFF1273EA),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.t(context, 'language.title'),
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 39,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 52),
                ],
              ),
              const SizedBox(height: 18),
              _LanguageTile(
                flag: '🇷🇺',
                title: AppStrings.t(context, 'language.russian'),
                selected: _selected == 'ru',
                onTap: () => setState(() => _selected = 'ru'),
              ),
              const SizedBox(height: 10),
              _LanguageTile(
                flag: '🇺🇸',
                title: AppStrings.t(context, 'language.english'),
                selected: _selected == 'en',
                onTap: () => setState(() => _selected = 'en'),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final localeProvider = context.read<LocaleProvider>();
                    await localeProvider.setLanguageCode(_selected);
                    if (!context.mounted) return;
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1479EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppStrings.t(context, 'common.save'),
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 25,
                    ),
                  ),
                ),
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
          color: Colors.white,
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
