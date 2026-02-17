import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
    } catch (_) {
      _isAvailable = false;
    }
    if (!_isAvailable) {
      return;
    }

    // Слушаем обновления покупок
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _iap.purchaseStream;
    purchaseUpdated.listen((purchases) {
      _purchaseController.add(purchases);
      _handlePurchases(purchases);
    });
  }

  Future<List<ProductDetails>> getProducts(Set<String> productIds) async {
    if (!_isAvailable) {
      return [];
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      throw Exception('Failed to query products: ${response.error}');
    }

    _products = response.productDetails;
    return _products;
  }

  Future<ProductDetails?> getProduct(String productId) async {
    if (_products.isEmpty) {
      await getProducts({productId});
    }
    return _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );
  }

  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }

    final ProductDetails? product = await getProduct(productId);
    if (product == null) {
      throw Exception('Product not found: $productId');
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      return false;
    }
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPurchased(String productId) async {
    // Проверка через Firebase или локальное хранилище
    // Здесь нужно реализовать проверку покупок
    return false;
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Обработка успешной покупки
        _completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        // Обработка ошибки
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    // Сохранение покупки в Firebase
    // Здесь нужно реализовать сохранение статуса покупки
  }

  void dispose() {
    _purchaseController.close();
  }
}
