import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../models/category.dart' as models;
import '../providers/animals_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/purchase_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Set<String> _expanded = {'pets'};
  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';
  static const Map<String, String> _categoryFolderById = {
    'farm': 'farm',
    'forest': 'forest',
    'savannah': 'Savannah',
    'pond': 'Pond',
    'jungle': 'Jungle',
  };

  String? _firstExistingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  Widget _categoryIcon(models.Category category) {
    final title = '${category.title.ru} ${category.title.en} ${category.id}'.toLowerCase();
    String? path;
    if (title.contains('pets') || title.contains('питом')) {
      path = _firstExistingPath(['$_imgBasePath\\Categories icons.png']);
    } else if (title.contains('farm') || title.contains('ферм')) {
      path = _firstExistingPath(['$_imgBasePath\\Group1.png', '$_imgBasePath\\Property 1=Farm, Size=XL.png']);
    } else if (title.contains('forest') || title.contains('лес')) {
      path = _firstExistingPath(['$_imgBasePath\\Icons2.png']);
    } else if (title.contains('savannah') || title.contains('саван')) {
      path = _firstExistingPath(['$_imgBasePath\\Savannah\\Categories icons.png', '$_imgBasePath\\savannah4.png']);
    } else if (title.contains('pond') || title.contains('poud') || title.contains('пруд')) {
      path = _firstExistingPath([
        '$_imgBasePath\\Pond\\Tab bar category image.png',
        '$_imgBasePath\\Property 1=Poud, Size=XL.png',
      ]);
    } else if (title.contains('jungle') || title.contains('джунг')) {
      path = _firstExistingPath(['$_imgBasePath\\Property 1=Jungle, Size=XL.png']);
    }
    if (path != null) {
      return Image.file(File(path), width: 38, height: 38, fit: BoxFit.contain);
    }
    return const Text('🐾', style: TextStyle(fontSize: 30));
  }

  Widget _animalIcon(Animal animal) {
    final folder = _categoryFolderById[animal.categoryId];
    if (folder != null) {
      final fileName = _localPreviewFileName(animal);
      if (fileName == null) {
        return const Text('🐾', style: TextStyle(fontSize: 34));
      }
      final path = '$_imgBasePath\\$folder\\$fileName';
      if (File(path).existsSync()) {
        return ClipOval(
          child: Image.file(File(path), width: 38, height: 38, fit: BoxFit.cover),
        );
      }
    }
    final previewRaw = animal.previewAssetPath;
    if (previewRaw != null && previewRaw.isNotEmpty && !previewRaw.startsWith('http')) {
      final local = previewRaw.startsWith('/') ? null : previewRaw;
      if (local != null && File(local).existsSync()) {
        return ClipOval(
          child: Image.file(File(local), width: 38, height: 38, fit: BoxFit.cover),
        );
      }
    }
    final name = animal.name.en.toLowerCase();
    if (name.contains('cat')) return const Text('🐱', style: TextStyle(fontSize: 34));
    if (name.contains('rabbit')) return const Text('🐰', style: TextStyle(fontSize: 34));
    if (name.contains('iguana')) return const Text('🦎', style: TextStyle(fontSize: 34));
    if (name.contains('hamster')) return const Text('🐹', style: TextStyle(fontSize: 34));
    if (name.contains('snail')) return const Text('🐌', style: TextStyle(fontSize: 34));
    if (name.contains('rat')) return const Text('🐭', style: TextStyle(fontSize: 34));
    if (name.contains('dog')) return const Text('🐶', style: TextStyle(fontSize: 34));
    return const Text('🐾', style: TextStyle(fontSize: 34));
  }

  String? _localPreviewFileName(Animal animal) {
    if (animal.categoryId == 'farm') {
      if (animal.order == 0) return 'Animal Card.png';
      if (animal.order == 1) return 'Image.png';
      return 'Image${animal.order - 1}.png';
    }
    return animal.order == 0 ? 'Image.png' : 'Image${animal.order}.png';
  }

  Color _cardColor(models.Category category) {
    final title = '${category.title.ru} ${category.title.en} ${category.id}'.toLowerCase();
    if (title.contains('pets') || title.contains('питом')) return const Color(0xFFCFE8FF);
    if (title.contains('farm') || title.contains('ферм')) return const Color(0xFFFFE2AA);
    if (title.contains('forest') || title.contains('лес')) return const Color(0xFFBDE7A5);
    if (title.contains('savannah') || title.contains('саван')) return const Color(0xFFFBE7A0);
    if (title.contains('pond') || title.contains('poud') || title.contains('пруд')) {
      return const Color(0xFFD4F1F2);
    }
    if (title.contains('jungle') || title.contains('джунг')) return const Color(0xFFD0EEBE);
    return const Color(0xFFEFF3F9);
  }

  bool _isLocked(models.Category category, PurchaseProvider purchaseProvider) {
    if (!category.isPaid) return false;
    final productId = category.iapProductId;
    if (productId == null || productId.isEmpty) return true;
    return !purchaseProvider.isPurchased(productId);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final categoriesProvider = context.watch<CategoriesProvider>();
    final animalsProvider = context.watch<AnimalsProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final categories = categoriesProvider.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.black, size: 24),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    final isLocked = _isLocked(c, purchaseProvider);
                    final expanded = _expanded.contains(c.id);
                    final animals = animalsProvider.getAnimals(c.id)..sort((a, b) => a.order.compareTo(b.order));
                    final title = c.title.getLocalized(locale);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: _cardColor(c),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _categoryIcon(c),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '0%  0 taps',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 15,
                                        color: Color(0xFF007AFF),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLocked)
                                GestureDetector(
                                  onTap: () async {
                                    final productId = c.iapProductId;
                                    if (productId == null || productId.isEmpty) return;
                                    final ok = await purchaseProvider.purchaseProduct(productId);
                                    if (!mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Покупка недоступна, открываю экран оплаты.'),
                                        ),
                                      );
                                      context.push('/purchases/offer');
                                      return;
                                    }
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 62,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Buy',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (expanded) {
                                      _expanded.remove(c.id);
                                    } else {
                                      _expanded.add(c.id);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: expanded ? const Color(0xFF007AFF) : Colors.white.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: expanded ? Colors.white : Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (expanded && !isLocked) ...[
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisExtent: 92,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: animals.length,
                              itemBuilder: (context, i) {
                                final a = animals[i];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _animalIcon(a),
                                    const SizedBox(height: 2),
                                    Text(
                                      a.name.getLocalized(locale),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Text(
                                      '0% / 0',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 12,
                                        color: Color(0xFF007AFF),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

