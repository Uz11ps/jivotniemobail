import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';
import '../providers/categories_provider.dart';
import '../providers/animals_provider.dart';
import '../services/firebase_service.dart';
import '../models/parental_test.dart';
import '../models/promotion.dart';
import '../utils/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Random _random = Random();
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _showDiscountBanner = true;
  Promotion? _activePromotion;
  bool _hasStats = false;
  List<({Widget icon, String label, String value})> _favoriteCategories = [];
  List<({Widget icon, String label, String value})> _favoriteWords = [];

  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';
  static const String _cursorAssetsBasePath =
      r'C:\Users\1\.cursor\projects\c-Users-1-Desktop-cursor-detiiosjivotnie\assets';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileStats();
      _loadActivePromotion();
    });
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('installation_id');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated =
        'device-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 31)}';
    await prefs.setString('installation_id', generated);
    return generated;
  }

  Future<void> _loadActivePromotion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _getOrCreateDeviceId();
      final promo = await _firebaseService.getActivePromotion(deviceId: deviceId);
      final dismissed = (prefs.getStringList('dismissed_promotions') ?? <String>[])
          .toSet();
      if (!mounted) return;
      if (promo == null || dismissed.contains(promo.id)) {
        setState(() {
          _activePromotion = null;
          _showDiscountBanner = false;
        });
        return;
      }
      setState(() {
        _activePromotion = promo;
        _showDiscountBanner = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activePromotion = null;
        _showDiscountBanner = false;
      });
    }
  }

  String? _existingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Widget _avatarOrEmoji({
    required List<String> candidatePaths,
    required String emojiFallback,
    double size = 38,
  }) {
    final path = _existingPath(candidatePaths);
    if (path != null) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Text(emojiFallback, style: TextStyle(fontSize: size - 6));
  }

  Widget _categoryIconByTitle(String title) {
    final lower = title.toLowerCase();
    String? iconPath;
    if (lower.contains('питом') || lower.contains('pets')) {
      iconPath = _existingPath([
        '$_imgBasePath\\Categories icons.png',
        '$_cursorAssetsBasePath\\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Categories_icons.png',
      ]);
    } else if (lower.contains('ферм') || lower.contains('farm')) {
      iconPath = _existingPath([
        '$_imgBasePath\\Group1.png',
        '$_cursorAssetsBasePath\\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Group1.png',
      ]);
    } else if (lower.contains('лес') || lower.contains('forest')) {
      iconPath = _existingPath([
        '$_imgBasePath\\Icons2.png',
        '$_cursorAssetsBasePath\\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Icons2.png',
      ]);
    } else if (lower.contains('саван') || lower.contains('savan')) {
      iconPath = _existingPath([
        '$_imgBasePath\\Savannah\\Categories icons.png',
        '$_imgBasePath\\savannah4.png',
        '$_cursorAssetsBasePath\\c__Users_1_Desktop_cursor_detiiosjivotnie_img_savannah4.png',
      ]);
    } else if (lower.contains('пруд') || lower.contains('pond') || lower.contains('poud')) {
      iconPath = _existingPath([
        '$_imgBasePath\\Pond\\Tab bar category image.png',
        '$_cursorAssetsBasePath\\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Pond_Tab_bar_category_image.png',
        '$_imgBasePath\\Property 1=Poud, Size=XL.png',
      ]);
    }
    if (iconPath != null) {
      return Image.file(
        File(iconPath),
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      );
    }
    return const Text('🐾', style: TextStyle(fontSize: 30));
  }

  Widget _wordIconByName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('соб')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 54.png'], emojiFallback: '🐶');
    }
    if (lower.contains('коров')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\image 1123.png'], emojiFallback: '🐮');
    }
    if (lower.contains('свин')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 56.png'], emojiFallback: '🐷');
    }
    if (lower.contains('лошад')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 61.png'], emojiFallback: '🐴');
    }
    if (lower.contains('кот')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 50.png'], emojiFallback: '🐱');
    }
    if (lower.contains('крол')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 51.png'], emojiFallback: '🐰');
    }
    if (lower.contains('череп')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 55.png'], emojiFallback: '🐢');
    }
    if (lower.contains('хом')) {
      return _avatarOrEmoji(candidatePaths: ['$_imgBasePath\\Frame 52.png'], emojiFallback: '🐹');
    }
    return _avatarOrEmoji(candidatePaths: [], emojiFallback: '🐾');
  }

  String _formatPercent(double value) {
    if (value >= 10) {
      return '${value.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  Future<void> _loadProfileStats() async {
    final locale = Localizations.localeOf(context).languageCode;
    final categoriesProvider = context.read<CategoriesProvider>();
    final animalsProvider = context.read<AnimalsProvider>();
    if (categoriesProvider.categories.isEmpty) {
      await categoriesProvider.loadCategories();
    }
    final categories = categoriesProvider.categories;
    if (categories.isEmpty) {
      if (mounted) {
        setState(() {
          _hasStats = false;
        });
      }
      return;
    }

    // Моментально показываем статистику по уже загруженным данным.
    _applyStats(locale, categories, animalsProvider);

    // Недостающие категории подгружаем параллельно, чтобы не тормозить экран.
    final toLoad = categories
        .where((category) => animalsProvider.getAnimals(category.id).isEmpty)
        .map((category) => animalsProvider.loadAnimals(category.id));
    await Future.wait(toLoad);
    _applyStats(locale, categories, animalsProvider);
  }

  void _applyStats(
    String locale,
    List categories,
    AnimalsProvider animalsProvider,
  ) {
    final categoryAnimalCounts = <String, int>{};
    var totalAnimals = 0;
    for (final category in categories) {
      final count = animalsProvider.getAnimals(category.id).length;
      categoryAnimalCounts[category.id] = count;
      totalAnimals += count;
    }

    final sortedCategories = List.of(categories)
      ..sort((a, b) => (categoryAnimalCounts[b.id] ?? 0).compareTo(categoryAnimalCounts[a.id] ?? 0));

    final favoriteCategories = sortedCategories.take(4).map((category) {
      final String title =
          category.title.en.isNotEmpty ? category.title.en : category.title.getLocalized(locale);
      final count = categoryAnimalCounts[category.id] ?? 0;
      final percent = totalAnimals == 0 ? 0.0 : (count / totalAnimals) * 100;
      return (
        icon: _categoryIconByTitle(title),
        label: title,
        value: _formatPercent(percent),
      );
    }).toList();

    final allAnimals = <String>[];
    for (final category in categories) {
      final names = animalsProvider
          .getAnimals(category.id)
          .map((animal) => animal.name.getLocalized(locale))
          .toList();
      allAnimals.addAll(names);
    }

    final freq = <String, int>{};
    for (final name in allAnimals) {
      freq[name] = (freq[name] ?? 0) + 1;
    }
    final sortedNames = freq.keys.toList()..sort((a, b) => (freq[b] ?? 0).compareTo(freq[a] ?? 0));
    final totalWords = allAnimals.isEmpty ? 1 : allAnimals.length;
    final favoriteWords = sortedNames.take(4).map((name) {
      final percent = ((freq[name] ?? 0) / totalWords) * 100;
      return (
        icon: _wordIconByName(name),
        label: name,
        value: _formatPercent(percent),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _favoriteCategories = favoriteCategories;
        _favoriteWords = favoriteWords;
        _hasStats = favoriteCategories.isNotEmpty && favoriteWords.isNotEmpty;
      });
    }
  }

  Future<void> _showParentalControl({
    required VoidCallback onSuccess,
  }) async {
    final List<ParentalTest> tests;
    try {
      tests = await _firebaseService.getParentalTests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t(context, 'profile.parentalLoadError'))),
        );
      }
      return;
    }

    if (!mounted) return;
    if (tests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'profile.parentalNoTests'))),
      );
      return;
    }

    final test = tests[_random.nextInt(tests.length)];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(context, 'profile.parentalTitle'),
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${test.left} ${test.operator} ${test.right} =',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1273EA),
                  ),
                ),
                const SizedBox(height: 14),
                ...test.answers.map(
                  (answer) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (answer == test.correctAnswer) {
                          Navigator.of(dialogContext).pop();
                          onSuccess();
                        }
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC6DAF3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$answer',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontWeight: FontWeight.w700,
                            fontSize: 34,
                            color: Color(0xFF1479EE),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeviceIdDialog() async {
    final deviceId = await _getOrCreateDeviceId();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.t(context, 'profile.deviceId')),
          content: SelectableText(
            deviceId,
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.t(context, 'profile.close')),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: deviceId));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.t(context, 'profile.deviceIdCopied'))),
                );
              },
              child: Text(AppStrings.t(context, 'profile.copy')),
            ),
          ],
        );
      },
    );
  }

  Widget _settingsRow({
    required Color iconColor,
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 15,
                    color: Color(0xFF8A8A8F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            trailingWidget ??
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF1273EA), size: 26),
          ],
        ),
      ),
    );
  }

  Widget _favoritesRow({
    required List<({Widget icon, String label, String value})> items,
    required bool hasData,
    VoidCallback? onItemTap,
  }) {
    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          AppStrings.t(context, 'profile.noData'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'SF Pro Rounded',
            fontSize: 17,
            height: 1.35,
            color: Color(0xFFB1B4C7),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: onItemTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item.icon,
                  const SizedBox(height: 4),
                  if (item.label.isNotEmpty)
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 26,
                      color: Color(0xFF1273EA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: items.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/categories');
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Color(0xFF1273EA), size: 24),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Parent Cabinet',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          if (_showDiscountBanner && _activePromotion != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8CD04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _activePromotion!.message.getLocalized(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: const TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final dismissed = (prefs.getStringList('dismissed_promotions') ?? <String>[])
                          .toSet();
                      dismissed.add(_activePromotion!.id);
                      await prefs.setStringList('dismissed_promotions', dismissed.toList());
                      if (!mounted) return;
                      setState(() => _showDiscountBanner = false);
                    },
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite categories',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _favoritesRow(
                  hasData: _hasStats,
                  items: _favoriteCategories,
                  onItemTap: () => context.push('/favorites'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top 10 favorite animals',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _favoritesRow(
                  hasData: _hasStats,
                  items: _favoriteWords,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Settings',
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _settingsRow(
                  iconColor: const Color(0xFF1BA5F5),
                  icon: Icons.format_list_numbered_rounded,
                  title: AppStrings.t(context, 'profile.categoriesOrder'),
                  onTap: () {
                    _showParentalControl(
                      onSuccess: () => context.push('/settings/order'),
                    );
                  },
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFFF5C400),
                  icon: Icons.notifications_none_rounded,
                  title: AppStrings.t(context, 'profile.notifications'),
                  trailingWidget: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF3AC159),
                  ),
                  onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFF7BC043),
                  icon: Icons.volume_up_outlined,
                  title: AppStrings.t(context, 'profile.soundEffects'),
                  trailingWidget: Switch(
                    value: _soundsEnabled,
                    onChanged: (value) => setState(() => _soundsEnabled = value),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF3AC159),
                  ),
                  onTap: () => setState(() => _soundsEnabled = !_soundsEnabled),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFF5AA4F8),
                  icon: Icons.language_rounded,
                  title: AppStrings.t(context, 'profile.language'),
                  trailingText: Localizations.localeOf(context).languageCode == 'ru'
                      ? AppStrings.t(context, 'profile.langRu')
                      : AppStrings.t(context, 'language.english'),
                  onTap: () => context.push('/settings/language'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Additional',
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _settingsRow(
                  iconColor: const Color(0xFFF5A400),
                  icon: Icons.shopping_cart_outlined,
                  title: AppStrings.t(context, 'profile.myPurchases'),
                  onTap: () => context.push('/purchases'),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFFA674F3),
                  icon: Icons.star_border_rounded,
                  title: AppStrings.t(context, 'profile.rateApp'),
                  onTap: () => context.push('/rate'),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFF8BC34A),
                  icon: Icons.ios_share_rounded,
                  title: AppStrings.t(context, 'profile.share'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.t(context, 'profile.shareSoon'))),
                    );
                  },
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  iconColor: const Color(0xFF6A6AF8),
                  icon: Icons.perm_device_info_outlined,
                  title: AppStrings.t(context, 'profile.deviceId'),
                  onTap: _showDeviceIdDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Telegram: скоро добавим ссылку')),
                );
              },
              child: Container(
                height: 56,
                width: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDF0),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF007AFF), size: 22),
                    SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Write to us in Telegram',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Application version 1.0.0',
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                fontSize: 16,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms: скоро добавим ссылку')),
                );
              },
              child: const Text(
                'Terms of Use and Privacy Policy',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF007AFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
