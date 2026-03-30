import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/animal.dart';
import '../models/parental_test.dart';
import '../models/category.dart' as models;
import '../providers/categories_provider.dart';
import '../providers/animals_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/firebase_service.dart';
import '../utils/app_strings.dart';
import '../utils/locale_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Random _random = Random();
  static const String _contentBaseUrl = 'http://168.222.193.86';
  static const String _petsHeroStaticImageUrl =
      'http://168.222.193.86/uploads/categories/hero/pets_hero_static.png';
  static const String _avatarBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';
  static const String _repoImgBaseUrl =
      'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';
  static const String _heroImagePrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Category Video.png';
  static const String _heroImageFallbackPath =
      '$_repoImgBaseUrl/Category%20Video.png';
  static const String _headerPetsPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Frame 43.png';
  static const String _headerPetsFallbackPath =
      '$_repoImgBaseUrl/Frame%2043.png';
  static const String _profileIconPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Icon.png';
  static const String _profileIconFallbackPath =
      '$_repoImgBaseUrl/Icon.png';
  static const String _warningPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\⚠️ Warning.png';
  static const String _lockVectorPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Vector (2).png';
  static const String _lockVectorFallbackPath =
      '$_repoImgBaseUrl/Vector%20%282%29.png';
  static const String _petsTopIconPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Property 1=Pets, Size=XL.png';
  static const String _petsTopIconFallbackPath =
      '$_repoImgBaseUrl/Property%201%3DPets%2C%20Size%3DXL.png';

  static const Map<String, String> _animalAvatarByKey = {
    'кот': 'Frame 50.png',
    'крол': 'Frame 51.png',
    'хом': 'Frame 52.png',
    'попуг': 'Frame 53.png',
    'соб': 'Frame 54.png',
    'череп': 'Frame 55.png',
    'свин': 'Frame 56.png',
    // В макете: сначала серая мышка, потом кролик, потом белая мышка.
    'мыш': 'Frame 57.png',
    'белая мыш': 'Frame 58.png',
    'улит': 'Frame 59.png',
    'ляг': 'Frame 60.png',
    'хор': 'Frame 61.png',
  };

  static const Map<String, String> _categoryNavIconByKey = {
    'питом': 'Property 1=Pets, Size=XL.png',
    'pets': 'Property 1=Pets, Size=XL.png',
    'ферм': 'Property 1=Farm, Size=XL.png',
    'farm': 'Property 1=Farm, Size=XL.png',
    'джунг': 'Property 1=Jungle, Size=XL.png',
    'jungle': 'Property 1=Jungle, Size=XL.png',
    'пруд': 'Pond\\Tab bar category image.png',
    'poud': 'Pond\\Tab bar category image.png',
    'pond': 'Pond\\Tab bar category image.png',
    'саван': 'Savannah\\Categories icons.png',
    'savannah': 'Savannah\\Categories icons.png',
    'лес': 'Property 1=Forest, Size=XL.png',
    'forest': 'Property 1=Forest, Size=XL.png',
  };
  static const Map<String, String> _categoryFolderById = {
    'farm': 'farm',
    'forest': 'forest',
    'savannah': 'Savannah',
    'pond': 'Pond',
    'jungle': 'Jungle',
  };

  String? _selectedCategoryId;
  VideoPlayerController? _heroVideoController;
  String? _heroVideoSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
      context.read<PurchaseProvider>().initialize();
    });
  }

  Future<void> _selectCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) {
      return;
    }
    setState(() => _selectedCategoryId = categoryId);
    await context.read<AnimalsProvider>().loadAnimals(categoryId);
  }

  @override
  void dispose() {
    _heroVideoController?.dispose();
    super.dispose();
  }

  String _emojiForAnimal(Animal animal) {
    final value = animal.name.ru.toLowerCase();
    if (value.contains('кот')) return '🐱';
    if (value.contains('крол')) return '🐰';
    if (value.contains('ляг')) return '🐸';
    if (value.contains('свин')) return '🐷';
    if (value.contains('соб')) return '🐶';
    if (value.contains('череп')) return '🐢';
    if (value.contains('мыш')) return '🐭';
    if (value.contains('хом')) return '🐹';
    if (value.contains('попуг')) return '🐥';
    if (value.contains('улит')) return '🐌';
    if (value.contains('коров')) return '🐮';
    if (value.contains('коза')) return '🐐';
    return '🐾';
  }

  String? _avatarPathForAnimal(Animal animal) {
    String remoteByFileName(String fileName) =>
        '$_repoImgBaseUrl/${Uri.encodeComponent(fileName)}';

    final value = animal.name.ru.toLowerCase();

    // Важно: "Белая мышь" содержит подстроку "мыш", поэтому даем приоритет.
    if (value.contains('бел') && value.contains('мыш')) {
      const fileName = 'Frame 58.png';
      const path = '$_avatarBasePath\\$fileName';
      if (File(path).existsSync()) {
        return path;
      }
      return remoteByFileName(fileName);
    }

    final entries = _animalAvatarByKey.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (value.contains(entry.key)) {
        final localPath = '$_avatarBasePath\\${entry.value}';
        if (File(localPath).existsSync()) {
          return localPath;
        }
        return remoteByFileName(entry.value);
      }
    }
    return null;
  }

  String? _localCategoryFolder(models.Category category) {
    return _categoryFolderById[category.id];
  }

  String? _localPreviewPathForAnimal(Animal animal) {
    final folder = _categoryFolderById[animal.categoryId];
    if (folder == null) return null;
    final fileName = _localPreviewFileName(animal);
    if (fileName == null) return null;
    final path = '$_avatarBasePath\\$folder\\$fileName';
    if (File(path).existsSync()) {
      return path;
    }
    return null;
  }

  String? _localPreviewFileName(Animal animal) {
    if (animal.categoryId == 'farm') {
      if (animal.order == 0) return 'Animal Card.png';
      if (animal.order == 1) return 'Image.png';
      return 'Image${animal.order - 1}.png';
    }
    return animal.order == 0 ? 'Image.png' : 'Image${animal.order}.png';
  }

  String _emojiForCategory(models.Category category) {
    final value = category.title.ru.toLowerCase();
    if (value.contains('питом')) return '🐱';
    if (value.contains('ферм')) return '🐷';
    if (value.contains('лес')) return '🐻';
    if (value.contains('джунг')) return '🐵';
    return '🐾';
  }

  String? _firstExistingPath(List<String> paths) {
    for (final path in paths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      if (path.startsWith('/')) {
        return '$_contentBaseUrl$path';
      }
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Widget _categoryIconWidget(models.Category category) {
    String remoteByFileName(String fileName) =>
        '$_repoImgBaseUrl/${Uri.encodeComponent(fileName.replaceAll('\\', '/'))}';

    Widget iconByFileName(String fileName, Widget fallback) {
      final localPath = '$_avatarBasePath\\$fileName';
      if (File(localPath).existsSync()) {
        return ClipOval(
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.file(
              File(localPath),
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      final remotePath = remoteByFileName(fileName);
      return ClipOval(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CachedNetworkImage(
            imageUrl: remotePath,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => fallback,
          ),
        ),
      );
    }

    final fallback = Text(
      _emojiForCategory(category),
      style: const TextStyle(fontSize: 34),
    );

    // Для блока Pets всегда используем переданную иконку.
    if (category.id.toLowerCase() == 'pets' || _isPetsCategory(category)) {
      return iconByFileName('Property 1=Pets, Size=XL.png', fallback);
    }

    final title = '${category.title.ru} ${category.title.en}'.toLowerCase();
    for (final entry in _categoryNavIconByKey.entries) {
      if (title.contains(entry.key)) {
        return iconByFileName(entry.value, fallback);
      }
    }

    final iconRaw = category.tabIconAssetPath.trim();
    final iconPath = iconRaw.startsWith('/') ? '$_contentBaseUrl$iconRaw' : iconRaw;
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return ClipOval(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CachedNetworkImage(
            imageUrl: iconPath,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => fallback,
          ),
        ),
      );
    }
    return fallback;
  }

  bool _isPetsCategory(models.Category category) {
    final all = '${category.id} ${category.title.ru} ${category.title.en}'.toLowerCase();
    return all.contains('pets') || all.contains('питом');
  }

  String? _petsTopIconPath() {
    return _firstExistingPath([
      _petsTopIconPrimaryPath,
      _petsTopIconFallbackPath,
    ]);
  }

  Future<void> _syncHeroVideo(models.Category selectedCategory) async {
    if (_isPetsCategory(selectedCategory)) {
      // Для Pets всегда статичная картинка без hero video.
      _heroVideoSource = null;
      await _heroVideoController?.dispose();
      _heroVideoController = null;
      if (mounted) setState(() {});
      return;
    }
    final localFolder = _localCategoryFolder(selectedCategory);
    if (localFolder != null) {
      final localHero = '$_avatarBasePath\\$localFolder\\Video.png';
      if (File(localHero).existsSync()) {
        _heroVideoSource = null;
        await _heroVideoController?.dispose();
        _heroVideoController = null;
        if (mounted) setState(() {});
        return;
      }
    }
    var raw = selectedCategory.heroVideoAssetPath?.trim();
    final url = (raw == null || raw.isEmpty)
        ? null
        : (raw.startsWith('/') ? '$_contentBaseUrl$raw' : raw);
    if (url == _heroVideoSource) return;
    _heroVideoSource = url;
    await _heroVideoController?.dispose();
    _heroVideoController = null;
    if (url == null || !(url.startsWith('http://') || url.startsWith('https://'))) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _heroVideoController = c;
      });
    } catch (_) {
      await _heroVideoController?.dispose();
      _heroVideoController = null;
      if (mounted) setState(() {});
    }
  }

  String? _heroImagePath(models.Category selectedCategory) {
    final localFolder = _localCategoryFolder(selectedCategory);
    if (localFolder != null) {
      final localHero = '$_avatarBasePath\\$localFolder\\Video.png';
      if (File(localHero).existsSync()) {
        return localHero;
      }
    }
    if (_isPetsCategory(selectedCategory)) {
      return _petsHeroStaticImageUrl;
    }
    final fromAdmin = selectedCategory.heroImageAssetPath?.trim();
    if (fromAdmin != null && fromAdmin.isNotEmpty) {
      return fromAdmin.startsWith('/') ? '$_contentBaseUrl$fromAdmin' : fromAdmin;
    }
    return _firstExistingPath([
      _heroImagePrimaryPath,
      _heroImageFallbackPath,
    ]);
  }

  Color _backgroundColor(models.Category selectedCategory) {
    final all = '${selectedCategory.id} ${selectedCategory.title.ru} ${selectedCategory.title.en}'
        .toLowerCase();
    if (all.contains('forest') || all.contains('лес')) {
      return const Color(0xFF4C8C2B);
    }
    if (all.contains('jungle') || all.contains('джунг')) {
      return const Color(0xFF7FC64F);
    }
    if (all.contains('savannah') || all.contains('саван')) {
      return const Color(0xFFF7D15E);
    }
    if (all.contains('pond') || all.contains('poud') || all.contains('пруд')) {
      return const Color(0xFF86D6D9);
    }
    final raw = selectedCategory.backgroundColorHex?.trim() ?? '';
    final hex = raw.replaceAll('#', '').toUpperCase();
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFF66AEF8);
  }

  String? _petsHeaderPath() {
    return _firstExistingPath([
      _headerPetsPrimaryPath,
      _headerPetsFallbackPath,
    ]);
  }

  String? _profileIconPath() {
    return _firstExistingPath([
      _profileIconPrimaryPath,
      _profileIconFallbackPath,
    ]);
  }

  String? _lockVectorPath() {
    return _firstExistingPath([
      _lockVectorPrimaryPath,
      _lockVectorFallbackPath,
    ]);
  }

  Widget _lockBadge() {
    final lockPath = _lockVectorPath();
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2475C8), width: 2),
      ),
      alignment: Alignment.center,
      child: lockPath == null
          ? const Icon(Icons.lock, size: 12, color: Color(0xFF2C74CF))
          : lockPath.startsWith('http://') || lockPath.startsWith('https://')
              ? CachedNetworkImage(
                  imageUrl: lockPath,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox.shrink(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.lock, size: 12, color: Color(0xFF2C74CF)),
                )
              : Image.file(
                  File(lockPath),
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
    );
  }

  Widget _headerTitle(models.Category selectedCategory, String locale) {
    final isPets = _isPetsCategory(selectedCategory);
    if (isPets) {
      final path = _petsTopIconPath();
      if (path != null) {
        final iconWidget = path.startsWith('http://') || path.startsWith('https://')
            ? CachedNetworkImage(
                imageUrl: path,
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 30,
                ),
              )
            : Image.file(
                File(path),
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            const Text(
              'Pets',
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: _categoryIconWidget(selectedCategory),
        ),
        const SizedBox(width: 6),
        Text(
          selectedCategory.title.getLocalized(locale),
          style: const TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _headerBar(models.Category selectedCategory, String locale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: _headerTitle(selectedCategory, locale)),
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: _openProfileWithParentalControl,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      final path = _profileIconPath();
                      if (path != null) {
                        if (path.startsWith('http://') || path.startsWith('https://')) {
                          return CachedNetworkImage(
                            imageUrl: path,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox.shrink(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, color: Color(0xFF2B6CB0), size: 24),
                          );
                        }
                        return Image.file(
                          File(path),
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        );
                      }
                      return const Icon(Icons.person, color: Color(0xFF2B6CB0), size: 24);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animalTile(Animal animal, VoidCallback onTap) {
    final avatarPath = _avatarPathForAnimal(animal);
    Widget avatar;
    // Приоритет: реальные данные из админки (URL), потом локальные картинки (dev-only), потом emoji.
    final previewRaw = animal.previewAssetPath;
    final preview = (previewRaw != null && previewRaw.startsWith('/'))
        ? '$_contentBaseUrl$previewRaw'
        : previewRaw;
    final localPreview = _localPreviewPathForAnimal(animal);
    if (preview != null && (preview.startsWith('http://') || preview.startsWith('https://'))) {
      avatar = CachedNetworkImage(
        imageUrl: preview,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) =>
            Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40)),
      );
    } else if (localPreview != null) {
      avatar = Image.file(File(localPreview), fit: BoxFit.contain);
    } else if (avatarPath != null) {
      if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
        avatar = CachedNetworkImage(
          imageUrl: avatarPath,
          fit: BoxFit.contain,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) =>
              Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40)),
        );
      } else {
        final file = File(avatarPath);
        if (file.existsSync()) {
          avatar = Image.file(file, fit: BoxFit.contain);
        } else {
          avatar = Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40));
        }
      }
    } else {
      avatar = Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40));
    }

    // По макету: 80.5x92, скругленный прямоугольник, Fill/Secondary 40%.
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80.5,
        height: 92,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x66F2F2F7),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: SizedBox(
              width: 66,
              height: 66,
              child: Center(child: avatar),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLocked(models.Category category, PurchaseProvider purchaseProvider) {
    if (!category.isPaid) {
      return false;
    }
    final productId = category.iapProductId;
    if (productId == null || productId.isEmpty) {
      return true;
    }
    return !purchaseProvider.isPurchased(productId);
  }

  bool _canAccess(models.Category category, PurchaseProvider purchaseProvider) {
    return !_isLocked(category, purchaseProvider);
  }

  String _warningFallbackPath() {
    return '$_repoImgBaseUrl/${Uri.encodeComponent('⚠️ Warning.png')}';
  }

  String? _warningImagePath() {
    return _firstExistingPath([
      _warningPrimaryPath,
      _warningFallbackPath(),
    ]);
  }

  Future<bool> _showParentalQuestionDialog(ParentalTest test) async {
    var isCorrect = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Parent control',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Solve a mathematical example',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${test.left} ${test.operator} ${test.right} =__',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 12),
                ...test.answers.map(
                  (answer) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        isCorrect = answer == test.correctAnswer;
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$answer',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
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
    return isCorrect;
  }

  Future<void> _showTryAgainDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        final warningPath = _warningImagePath();
        Widget warningWidget = const Text('⚠️', style: TextStyle(fontSize: 96));
        if (warningPath != null) {
          if (warningPath.startsWith('http://') || warningPath.startsWith('https://')) {
            warningWidget = CachedNetworkImage(
              imageUrl: warningPath,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => const Text('⚠️', style: TextStyle(fontSize: 96)),
            );
          } else {
            warningWidget = Image.file(
              File(warningPath),
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            );
          }
        }
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                warningWidget,
                const SizedBox(height: 8),
                const Text(
                  'Parent control',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Solve a mathematical example',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Oops! Try again!',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF5CB8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openProfileWithParentalControl() async {
    final List<ParentalTest> tests;
    try {
      tests = await _firebaseService.getParentalTests();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'profile.parentalLoadError'))),
      );
      return;
    }

    if (!mounted) return;
    if (tests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'profile.parentalNoTests'))),
      );
      return;
    }

    while (mounted) {
      final test = tests[_random.nextInt(tests.length)];
      final isCorrect = await _showParentalQuestionDialog(test);
      if (!mounted) return;
      if (isCorrect) {
        context.go('/profile');
        return;
      }
      await _showTryAgainDialog();
      if (!mounted) return;
    }
  }

  String _pickFirstAccessibleCategoryId(
    List<models.Category> categories,
    PurchaseProvider purchaseProvider,
  ) {
    for (final c in categories) {
      if (_canAccess(c, purchaseProvider)) {
        return c.id;
      }
    }
    // Если все закрыты (не должно быть в нормальном сценарии) — оставляем первую.
    return categories.first.id;
  }

  Future<void> _onCategoryTap(
    models.Category category,
    PurchaseProvider purchaseProvider,
  ) async {
    if (_isLocked(category, purchaseProvider)) {
      final shouldBuy = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.t(context, 'categories.lockedTitle')),
          content: Text(AppStrings.t(context, 'categories.lockedText')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppStrings.t(context, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppStrings.t(context, 'common.ok')),
            ),
          ],
        ),
      );
      if (shouldBuy == true) {
        final productId = category.iapProductId;
        if (productId != null && productId.isNotEmpty) {
          final ok = await purchaseProvider.purchaseProduct(productId);
          if (!mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось выполнить покупку. Проверьте App Store Connect / Product ID.')),
            );
          }
          if (ok) {
            await _selectCategory(category.id);
          }
        }
      }
      return;
    }
    await _selectCategory(category.id);
    try {
      await _firebaseService.logEvent('category_open', {
        'categoryId': category.id,
        'categoryTitleRu': category.title.ru,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<CategoriesProvider, AnimalsProvider, PurchaseProvider>(
        builder: (context, categoriesProvider, animalsProvider, purchaseProvider, child) {
          if (categoriesProvider.isLoading) {
            return const ColoredBox(
              color: Color(0xFF66AEF8),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (categoriesProvider.categories.isEmpty) {
            return ColoredBox(
              color: const Color(0xFF66AEF8),
              child: Center(
                child: Text(
                  AppStrings.t(context, 'categories.empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'SF Pro Rounded',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            );
          }

          final categories = categoriesProvider.categories;

            final desiredSelectedId = _pickFirstAccessibleCategoryId(categories, purchaseProvider);
            final currentSelected = _selectedCategoryId;
            final currentSelectedCategory = currentSelected == null
                ? null
                : categories.where((c) => c.id == currentSelected).isNotEmpty
                    ? categories.firstWhere((c) => c.id == currentSelected)
                    : null;

            final shouldAutoFixSelection =
                currentSelected == null || currentSelectedCategory == null || _isLocked(currentSelectedCategory, purchaseProvider);

            final effectiveSelectedId = shouldAutoFixSelection ? desiredSelectedId : currentSelected;

            // Не дергаем setState прямо в build. Фиксируем выбранную категорию после кадра.
            if (_selectedCategoryId != effectiveSelectedId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedCategoryId = effectiveSelectedId);
              });
            }

            final selectedCategory = categories.firstWhere(
              (category) => category.id == effectiveSelectedId,
              orElse: () => categories.first,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncHeroVideo(selectedCategory);
            });
            final locale = LocaleHelper.getCurrentLocale(context);
            final bgColor = _backgroundColor(selectedCategory);

            final animals = animalsProvider.getAnimals(selectedCategory.id);
            if (animals.isEmpty && !animalsProvider.isLoading(selectedCategory.id)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AnimalsProvider>().loadAnimals(selectedCategory.id);
              });
            }

          return ColoredBox(
            color: bgColor,
            child: SafeArea(
              child: Column(
                children: [
                _headerBar(selectedCategory, locale),
                SizedBox(
                  width: 250,
                  height: 180,
                  child: Builder(
                    builder: (context) {
                      if (_heroVideoController != null &&
                          _heroVideoController!.value.isInitialized) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _heroVideoController!.value.size.width,
                              height: _heroVideoController!.value.size.height,
                              child: VideoPlayer(_heroVideoController!),
                            ),
                          ),
                        );
                      }
                      final heroPath = _heroImagePath(selectedCategory);
                      if (heroPath != null) {
                        if (heroPath.startsWith('http://') || heroPath.startsWith('https://')) {
                          return CachedNetworkImage(
                            imageUrl: heroPath,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => const SizedBox.shrink(),
                            errorWidget: (context, url, error) => const SizedBox.shrink(),
                          );
                        }
                        return Image.file(
                          File(heroPath),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                      return const Stack(
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: Text('🏠', style: TextStyle(fontSize: 92)),
                            ),
                          ),
                          Positioned(left: 16, bottom: 12, child: Text('🐶', style: TextStyle(fontSize: 28))),
                          Positioned(right: 16, bottom: 12, child: Text('🐱', style: TextStyle(fontSize: 28))),
                          Positioned(left: 16, top: 12, child: Text('🐦', style: TextStyle(fontSize: 24))),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SingleChildScrollView(
                      child: Builder(
                        builder: (context) {
                          final animalsSorted = List<Animal>.from(animals)
                            ..sort((a, b) => a.order.compareTo(b.order));
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisExtent: 92,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: animalsSorted.length,
                            itemBuilder: (context, index) {
                              final animal = animalsSorted[index];
                              return Center(
                                child: _animalTile(
                                  animal,
                                  () async {
                                    try {
                                      await _firebaseService.logEvent('animal_open', {
                                        'categoryId': selectedCategory.id,
                                        'animalId': animal.id,
                                        'animalNameRu': animal.name.ru,
                                      });
                                    } catch (_) {}
                                    if (!context.mounted) return;
                                    context.go('/categories/${selectedCategory.id}/animals/${animal.id}');
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 8, 15, 16),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 345),
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4893DE),
                          borderRadius: BorderRadius.circular(119),
                          border: Border.all(color: const Color(0xFF2475C8), width: 2),
                        ),
                        child: ScrollConfiguration(
                          behavior: const _HorizontalNavScrollBehavior(),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category.id == selectedCategory.id;
                              final isLocked = _isLocked(category, purchaseProvider);
                              const bgColor = Colors.white30;

                              return GestureDetector(
                                onTap: () => _onCategoryTap(category, purchaseProvider),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? 2 : 4,
                                    right: index == categories.length - 1 ? 2 : 4,
                                  ),
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bgColor,
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFF2475C8), width: 3)
                                        : null,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.hardEdge,
                                    children: [
                                      Center(
                                        child: _categoryIconWidget(category),
                                      ),
                                      if (isLocked)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: _lockBadge(),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}

class _HorizontalNavScrollBehavior extends MaterialScrollBehavior {
  const _HorizontalNavScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
