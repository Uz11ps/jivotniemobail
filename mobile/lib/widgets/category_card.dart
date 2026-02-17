import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/category.dart';
import '../providers/purchase_provider.dart';
import '../utils/locale_helper.dart';

class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  String? _iconUrl;
  bool _isLoadingIcon = true;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    if (widget.category.tabIconAssetPath.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingIcon = false);
      }
      return;
    }

    // Если уже лежит URL (мы так теперь сохраняем из админки) — используем его напрямую.
    if (widget.category.tabIconAssetPath.startsWith('http://') ||
        widget.category.tabIconAssetPath.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _iconUrl = widget.category.tabIconAssetPath;
          _isLoadingIcon = false;
        });
      }
      return;
    }

    try {
      final storage = FirebaseStorage.instance;
      final url = await storage.ref(widget.category.tabIconAssetPath).getDownloadURL();
      if (mounted) {
        setState(() {
          _iconUrl = url;
          _isLoadingIcon = false;
        });
      }
    } catch (e) {
      // Иконка недоступна, используем дефолтную
      if (mounted) {
        setState(() {
          _isLoadingIcon = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleHelper.getCurrentLocale(context);
    final title = widget.category.title.getLocalized(locale);
    final isPurchased = context.watch<PurchaseProvider>().isPurchased(
          widget.category.iapProductId ?? '',
        );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: widget.category.isPaid && !isPurchased
            ? () => _showPurchaseDialog(context)
            : widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingIcon)
                      const CircularProgressIndicator(color: Colors.white)
                    else if (_iconUrl != null)
                      CachedNetworkImage(
                        imageUrl: _iconUrl!,
                        width: 80,
                        height: 80,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.pets, size: 80, color: Colors.white),
                      )
                    else
                      const Icon(Icons.pets, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.category.isPaid && !isPurchased)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Платно',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Платная категория'),
        content: Text(
          'Эта категория доступна за дополнительную плату. Хотите приобрести?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final purchaseProvider =
                  Provider.of<PurchaseProvider>(context, listen: false);
              final success = await purchaseProvider.purchaseProduct(
                widget.category.iapProductId!,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Покупка успешна!')),
                );
              }
            },
            child: const Text('Купить'),
          ),
        ],
      ),
    );
  }
}
