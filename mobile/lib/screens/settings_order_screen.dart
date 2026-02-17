import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as models;
import '../providers/categories_provider.dart';
import '../providers/purchase_provider.dart';
import '../utils/app_strings.dart';

class SettingsOrderScreen extends StatefulWidget {
  const SettingsOrderScreen({super.key});

  @override
  State<SettingsOrderScreen> createState() => _SettingsOrderScreenState();
}

class _SettingsOrderScreenState extends State<SettingsOrderScreen> {
  List<models.Category> _localCategories = [];
  bool _initialized = false;

  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final categories = context.read<CategoriesProvider>().categories;
    _localCategories = List<models.Category>.from(categories);
    _initialized = true;
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

  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    PurchaseProvider purchaseProvider,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) {
      return;
    }

    final oldItem = _localCategories[oldIndex];
    if (_isLocked(oldItem, purchaseProvider)) {
      return;
    }
    if (_isLocked(_localCategories[newIndex], purchaseProvider)) {
      return;
    }

    final moved = _localCategories.removeAt(oldIndex);
    _localCategories.insert(newIndex, moved);
    setState(() {});
    await context.read<CategoriesProvider>().reorderCategories(
          oldIndex: oldIndex,
          newIndex: newIndex,
        );
    if (!mounted) {
      return;
    }
    _localCategories = List<models.Category>.from(context.read<CategoriesProvider>().categories);
    if (mounted) {
      setState(() {});
    }
  }

  String _displayTitle(models.Category category, String locale) {
    return category.title.getLocalized(locale);
  }

  String? _firstExistingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Widget _iconForTitle(String title) {
    final lower = title.toLowerCase();
    String? path;
    if (lower.contains('домаш') || lower.contains('питом') || lower.contains('pet')) {
      path = _firstExistingPath(['$_imgBasePath\\🐱 Cat Face Frontal.png', '$_imgBasePath\\Frame 50.png']);
    } else if (lower.contains('лес') || lower.contains('forest')) {
      path = _firstExistingPath(['$_imgBasePath\\🐻 Bear Frontal.png']);
    } else if (lower.contains('мор') || lower.contains('рыб') || lower.contains('sea')) {
      path = _firstExistingPath(['$_imgBasePath\\Frame 53.png']);
    } else if (lower.contains('насеком') || lower.contains('insect')) {
      path = _firstExistingPath(['$_imgBasePath\\Frame 43.png']);
    } else if (lower.contains('транспорт') || lower.contains('transport')) {
      path = _firstExistingPath(['$_imgBasePath\\Icon.png']);
    } else if (lower.contains('фрукт') || lower.contains('fruit')) {
      path = _firstExistingPath(['$_imgBasePath\\image 1094.png']);
    } else if (lower.contains('овощ') || lower.contains('vegetable')) {
      path = _firstExistingPath(['$_imgBasePath\\image 1123.png']);
    }
    if (path != null) {
      return ClipOval(
        child: Image.file(File(path), width: 30, height: 30, fit: BoxFit.cover),
      );
    }
    return const Text('🐾', style: TextStyle(fontSize: 24));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().categories;
    final purchaseProvider = context.watch<PurchaseProvider>();
    final locale = Localizations.localeOf(context).languageCode;

    final localIds = _localCategories.map((category) => category.id).join(',');
    final providerIds = categories.map((category) => category.id).join(',');
    if (categories.isNotEmpty && localIds != providerIds) {
      _localCategories = List<models.Category>.from(categories);
    }

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
                    AppStrings.t(context, 'order.title'),
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 52),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _localCategories.length,
                  onReorder: (oldIndex, newIndex) =>
                      _handleReorder(oldIndex, newIndex, purchaseProvider),
                  itemBuilder: (context, index) {
                    final category = _localCategories[index];
                    final title = _displayTitle(category, locale);
                    final isLocked = _isLocked(category, purchaseProvider);
                    return Container(
                      key: ValueKey(category.id),
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 66,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLocked ? const Color(0xFFE9E9EE) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          _iconForTitle(title),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'SF Pro Rounded',
                                fontSize: 17,
                                color: isLocked ? const Color(0xFF9B9BA2) : const Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isLocked)
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                size: 24,
                                color: Color(0xFF1273EA),
                              ),
                            )
                          else
                            const Row(
                              children: [
                                _PriceBadge(),
                                SizedBox(width: 8),
                                Icon(Icons.lock, size: 18, color: Colors.black87),
                              ],
                            ),
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

class _PriceBadge extends StatelessWidget {
  const _PriceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1273EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        AppStrings.t(context, 'order.price'),
        style: const TextStyle(
          fontFamily: 'SF Pro Rounded',
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
