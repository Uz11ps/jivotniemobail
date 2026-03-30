import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../providers/purchase_provider.dart';

class PurchaseOfferScreen extends StatelessWidget {
  const PurchaseOfferScreen({super.key});

  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';

  String? _existingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().categories;
    final purchaseProvider = context.watch<PurchaseProvider>();
    final offerPath = _existingPath(['$_imgBasePath\\Group 7 1.png']);

    return Scaffold(
      backgroundColor: const Color(0xFFFF5DC1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC8E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left, size: 20, color: Colors.black),
                          SizedBox(width: 2),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: offerPath != null
                    ? Image.file(File(offerPath), fit: BoxFit.contain)
                    : const Center(
                        child: Text(
                          'SPECIAL OFFER',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    String? productId;
                    for (final c in categories) {
                      if (c.isPaid && (c.iapProductId ?? '').isNotEmpty) {
                        productId = c.iapProductId;
                        break;
                      }
                    }
                    if (productId == null || productId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product ID не найден')),
                      );
                      return;
                    }
                    final ok = await context.read<PurchaseProvider>().purchaseProduct(productId);
                    if (!context.mounted) return;
                    if (ok) {
                      context.go('/purchases');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Оплата не прошла. Проверь App Store/StoreKit.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text(
                    'Buy for \$8.00',
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
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

