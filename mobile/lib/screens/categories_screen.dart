import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/animal.dart';
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
  static const String _avatarBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';
  static const String _heroImagePrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Главная пикча.png';
  static const String _heroImageFallbackPath =
      r'C:\Users\1\.cursor\projects\c-Users-1-Desktop-cursor-detiiosjivotnie\assets\c__Users_1_Desktop_cursor_detiiosjivotnie_img______________.png';
  static const String _headerPetsPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Frame 43.png';
  static const String _headerPetsFallbackPath =
      r'C:\Users\1\.cursor\projects\c-Users-1-Desktop-cursor-detiiosjivotnie\assets\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Frame_43.png';
  static const String _profileIconPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Icon.png';
  static const String _profileIconFallbackPath =
      r'C:\Users\1\.cursor\projects\c-Users-1-Desktop-cursor-detiiosjivotnie\assets\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Icon.png';
  static const String _lockVectorPrimaryPath =
      r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img\Vector (2).png';
  static const String _lockVectorFallbackPath =
      r'C:\Users\1\.cursor\projects\c-Users-1-Desktop-cursor-detiiosjivotnie\assets\c__Users_1_Desktop_cursor_detiiosjivotnie_img_Vector__2_.png';

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

  String? _selectedCategoryId;

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
    final value = animal.name.ru.toLowerCase();

    // Важно: "Белая мышь" содержит подстроку "мыш", поэтому даем приоритет.
    if (value.contains('бел') && value.contains('мыш')) {
      const path = '$_avatarBasePath\\Frame 58.png';
      if (File(path).existsSync()) {
        return path;
      }
    }

    final entries = _animalAvatarByKey.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (value.contains(entry.key)) {
        return '$_avatarBasePath\\${entry.value}';
      }
    }
    return null;
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
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Widget _categoryIconWidget(models.Category category) {
    final iconPath = category.tabIconAssetPath.trim();
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        width: 52,
        height: 52,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) =>
            Text(_emojiForCategory(category), style: const TextStyle(fontSize: 34)),
      );
    }
    return Text(
      _emojiForCategory(category),
      style: const TextStyle(fontSize: 34),
    );
  }

  String? _heroImagePath() {
    return _firstExistingPath([
      _heroImagePrimaryPath,
      _heroImageFallbackPath,
    ]);
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
      child: lockPath != null
          ? Image.file(
              File(lockPath),
              width: 14,
              height: 14,
              fit: BoxFit.contain,
            )
          : const Icon(Icons.lock, size: 12, color: Color(0xFF2C74CF)),
    );
  }

  Widget _headerTitle(models.Category selectedCategory, String locale) {
    final isPets = selectedCategory.title.ru.toLowerCase().contains('питом');
    if (isPets) {
      final path = _petsHeaderPath();
      if (path != null) {
        return Image.file(
          File(path),
          height: 26,
          fit: BoxFit.contain,
        );
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.home_rounded, color: Colors.white, size: 20),
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
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      final path = _profileIconPath();
                      if (path != null) {
                        return Image.file(
                          File(path),
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        );
                      }
                      return const Icon(Icons.person, color: Color(0xFF2B6CB0), size: 28);
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
    final preview = animal.previewAssetPath;
    if (preview != null && (preview.startsWith('http://') || preview.startsWith('https://'))) {
      avatar = CachedNetworkImage(
        imageUrl: preview,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) =>
            Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40)),
      );
    } else if (avatarPath != null) {
      final file = File(avatarPath);
      if (file.existsSync()) {
        avatar = Image.file(file, fit: BoxFit.contain);
      } else {
        avatar = Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40));
      }
    } else {
      avatar = Text(_emojiForAnimal(animal), style: const TextStyle(fontSize: 40));
    }

    // По фигме: 75x75, круглый фон #FFFFFF 30%, мордочка поверх круга.
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        height: 75,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
            // Не даем аватарке вылезать за пределы ячейки (иначе визуально "дублируется"/налезает).
            SizedBox(
              width: 70,
              height: 70,
              child: Center(child: avatar),
            ),
          ],
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
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.t(context, 'categories.lockedTitle')),
          content: Text(AppStrings.t(context, 'categories.lockedText')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.t(context, 'common.ok')),
            ),
          ],
        ),
      );
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
    final locale = LocaleHelper.getCurrentLocale(context);
    return Scaffold(
      backgroundColor: const Color(0xFF66AEF8),
      body: SafeArea(
        child: Consumer3<CategoriesProvider, AnimalsProvider, PurchaseProvider>(
          builder: (context, categoriesProvider, animalsProvider, purchaseProvider, child) {
            if (categoriesProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (categoriesProvider.categories.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.t(context, 'categories.empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'SF Pro Rounded',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

            final animals = animalsProvider.getAnimals(selectedCategory.id);
            if (animals.isEmpty && !animalsProvider.isLoading(selectedCategory.id)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AnimalsProvider>().loadAnimals(selectedCategory.id);
              });
            }

            return Column(
              children: [
                _headerBar(selectedCategory, locale),
                SizedBox(
                  width: 250,
                  height: 180,
                  child: Builder(
                    builder: (context) {
                      final heroPath = _heroImagePath();
                      if (heroPath != null) {
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
                              mainAxisExtent: 75,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 20,
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
                              final bgColor = isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.30);

                              return GestureDetector(
                                onTap: () => _onCategoryTap(category, purchaseProvider),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? 2 : 8,
                                    right: index == categories.length - 1 ? 2 : 8,
                                  ),
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bgColor,
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFF2475C8), width: 4)
                                        : null,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
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
            );
          },
        ),
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
