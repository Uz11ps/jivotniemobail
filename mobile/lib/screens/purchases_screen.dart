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

  String? _iconPathForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('питом') || lower.contains('pets')) {
      return _existingPath(['$_imgBasePath\\Categories icons.png']);
    }
    if (lower.contains('ферм') || lower.contains('farm')) {
      return _existingPath(['$_imgBasePath\\Group1.png', '$_imgBasePath\\Property 1=Farm, Size=XL.png']);
    }
    if (lower.contains('лес') || lower.contains('forest')) {
      return _existingPath(['$_imgBasePath\\Icons2.png']);
    }
    if (lower.contains('саван') || lower.contains('savannah')) {
      return _existingPath(['$_imgBasePath\\Savannah\\Categories icons.png', '$_imgBasePath\\savannah4.png']);
    }
    if (lower.contains('пруд') || lower.contains('pond') || lower.contains('poud')) {
      return _existingPath([
        '$_imgBasePath\\Pond\\Tab bar category image.png',
        '$_imgBasePath\\Property 1=Poud, Size=XL.png',
      ]);
    }
    if (lower.contains('джунг') || lower.contains('jungle')) {
      return _existingPath(['$_imgBasePath\\Property 1=Jungle, Size=XL.png']);
    }
    return null;
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
                            final path = _existingPath([
                              '$_imgBasePath\\тигр-подмигивает-и-улыбается 1.png',
                              '$_imgBasePath\\тигр-подмигивает-и-улыбается 11.png',
                            ]);
                            if (path != null) {
                              return Image.file(File(path), width: 220, height: 220, fit: BoxFit.contain);
                            }
                            return const Text('🐯', style: TextStyle(fontSize: 140));
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "You haven't made any purchases\nyet. Maybe we should buy some?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 24,
                            color: Color(0xFF1D1D1F),
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.push('/purchases/offer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 26),
                              child: Text(
                                'Go shopping!',
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  color: Colors.white,
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
                      ...purchasedCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final title = category.title.getLocalized(locale);
                        final iconPath = _iconPathForTitle(title);
                        final date = DateTime.now().subtract(Duration(days: index * 3));
                        final dateText =
                            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}';
                        final timeText =
                            '${(12 + index).toString().padLeft(2, '0')}:${(5 + index * 7).toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PurchaseHistoryTile(
                            title: '${title} pack',
                            iconPath: iconPath,
                            emoji: _emojiForTitle(title),
                            orderId: '#${331852 + index * 5}',
                            dateText: dateText,
                            timeText: timeText,
                            priceText: '\$2.00',
                            cardText: '* 3384',
                          ),
                        );
                      }),
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

class _PurchaseHistoryTile extends StatelessWidget {
  final String title;
  final String? iconPath;
  final String emoji;
  final String orderId;
  final String dateText;
  final String timeText;
  final String priceText;
  final String cardText;

  const _PurchaseHistoryTile({
    required this.title,
    required this.iconPath,
    required this.emoji,
    required this.orderId,
    required this.dateText,
    required this.timeText,
    required this.priceText,
    required this.cardText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (iconPath != null)
                Image.file(
                  File(iconPath!),
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                orderId,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: Color(0xFF9A9AA2),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.copy_all_outlined, color: Color(0xFF007AFF), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _kv('Date and time of purchase', dateText),
          _divider(),
          _kv('Time of puchare', timeText),
          _divider(),
          _kv('Purchase price', priceText),
          _divider(),
          _kv('Card number', cardText),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1),
      );

  Widget _kv(String key, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            key,
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'SF Pro Rounded',
            fontSize: 15,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
