import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../providers/purchase_provider.dart';
import '../utils/app_strings.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  bool _requestedLoad = false;

  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';

  String? _existingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  String _emojiForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('insect')) return '🐞';
    if (lower.contains('transport')) return '🚁';
    if (lower.contains('fruit')) return '🍉';
    if (lower.contains('vegetable')) return '🍅';
    if (lower.contains('forest')) return '🐻';
    if (lower.contains('sea')) return '🐠';
    if (lower.contains('farm')) return '🐷';
    if (lower.contains('насеком')) return '🐞';
    if (lower.contains('транспорт')) return '🚁';
    if (lower.contains('фрукт')) return '🍉';
    if (lower.contains('овощ')) return '🍅';
    if (lower.contains('лес')) return '🐻';
    if (lower.contains('мор')) return '🐠';
    if (lower.contains('ферм')) return '🐷';
    return '🐾';
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final categoriesProvider = context.watch<CategoriesProvider>();
    if (!_requestedLoad && categoriesProvider.categories.isEmpty) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CategoriesProvider>().loadCategories();
      });
    }

    final locale = Localizations.localeOf(context).languageCode;
    final purchasedCategories = categoriesProvider.categories.where((category) {
      if (!category.isPaid) {
        return false;
      }
      final productId = category.iapProductId;
      if (productId == null || productId.isEmpty) {
        return false;
      }
      return purchaseProvider.isPurchased(productId);
    }).toList();
    final hasPurchases = purchasedCategories.isNotEmpty;

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
                    AppStrings.t(context, 'purchases.title'),
                    style: const TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 52),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasPurchases)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) {
                            final path = _existingPath(['$_imgBasePath\\Frame 52.png']);
                            if (path != null) {
                              return Image.file(File(path), width: 180, height: 180, fit: BoxFit.contain);
                            }
                            return const Text('🎁', style: TextStyle(fontSize: 120));
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.t(context, 'purchases.emptyTitle'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.t(context, 'purchases.emptySubtitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 30,
                            color: Color(0xFF70747B),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.go('/categories'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCDE3FA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 26),
                              child: Text(
                                AppStrings.t(context, 'purchases.buyPacks'),
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  color: Color(0xFF1273EA),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      ...purchasedCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PurchaseTile(
                            title: category.title.getLocalized(locale),
                            emoji: _emojiForTitle(category.title.getLocalized(locale)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final String title;
  final String emoji;

  const _PurchaseTile({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
