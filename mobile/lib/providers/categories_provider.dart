import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/category.dart' as models;
import '../services/firebase_service.dart';

class CategoriesProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<models.Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<models.Category>>? _sub;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoriesProvider() {
    // Реальные обновления порядка/видимости приходят из Firestore в realtime.
    _sub = _firebaseService.getCategoriesStream().listen(
      (cats) {
        _categories = cats;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _firebaseService.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading categories: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> reorderCategories({
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _categories.length ||
        newIndex >= _categories.length) {
      return;
    }

    final updated = List<models.Category>.from(_categories);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    _categories = List<models.Category>.generate(
      updated.length,
      (index) => updated[index].copyWith(order: index),
    );
    notifyListeners();

    try {
      await _firebaseService.updateCategoryOrders(_categories);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating category order: $e');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
