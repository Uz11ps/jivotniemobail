import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseProvider with ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  final FirebaseService _firebaseService = FirebaseService();
  Set<String> _purchasedProducts = {};
  bool _isInitialized = false;

  Set<String> get purchasedProducts => _purchasedProducts;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _purchaseService.initialize();
    } catch (_) {
      // In-app purchases are not available on this platform.
    }
    await _loadPurchasedProducts();
    _isInitialized = true;
    notifyListeners();

    // Слушаем обновления покупок
    _purchaseService.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _purchasedProducts.add(purchase.productID);
          _savePurchasedProducts();
          notifyListeners();
        }
      }
    });
  }

  Future<bool> purchaseProduct(String productId) async {
    try {
      final success = await _purchaseService.purchaseProduct(productId);
      if (success) {
        await _grantLocalPurchase(productId);
        try {
          await _firebaseService.logEvent('purchase_success', {
            'productId': productId,
          });
        } catch (_) {}
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error purchasing product: $e');
      }
      // На Windows StoreKit/Google Play недоступны: разрешаем локальный dev-fallback.
      if (!kIsWeb && Platform.isWindows) {
        await _grantLocalPurchase(productId);
        return true;
      }
      return false;
    }
  }

  Future<void> markPurchasedForDev(String productId) async {
    await _grantLocalPurchase(productId);
  }

  Future<bool> restorePurchases() async {
    try {
      final success = await _purchaseService.restorePurchases();
      if (success) {
        await _loadPurchasedProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring purchases: $e');
      }
      return false;
    }
  }

  bool isPurchased(String productId) {
    return _purchasedProducts.contains(productId);
  }

  Future<void> _loadPurchasedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList('purchased_products') ?? [];
    _purchasedProducts = purchased.toSet();
  }

  Future<void> _savePurchasedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'purchased_products',
      _purchasedProducts.toList(),
    );
  }

  Future<void> _grantLocalPurchase(String productId) async {
    _purchasedProducts.add(productId);
    await _savePurchasedProducts();
    notifyListeners();
  }
}
