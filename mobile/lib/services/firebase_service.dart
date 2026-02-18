import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/animal.dart';
import '../models/offer.dart';
import '../models/parental_test.dart';
import '../models/promotion.dart';
import 'firestore_rest_service.dart';

class FirebaseService {
  static const String _analyticsBaseUrl =
      String.fromEnvironment('ANALYTICS_BASE_URL', defaultValue: 'http://168.222.193.86');
  static const String _contentBaseUrl =
      String.fromEnvironment('CONTENT_BASE_URL', defaultValue: 'http://168.222.193.86');
  static const String _analyticsIngestKey =
      String.fromEnvironment('ANALYTICS_INGEST_KEY', defaultValue: 'analytics123');

  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  bool _isInitialized = false;

  FirebaseService() {
    // Firestore нам нужен всегда (контент). Storage может быть недоступен/платный — это не должно ломать всё.
    try {
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
    } catch (_) {
      _firestore = null;
      _isInitialized = false;
    }

    try {
      _storage = FirebaseStorage.instance;
    } catch (_) {
      _storage = null;
    }
  }

  bool get isInitialized => _isInitialized;

  bool get _preferRestOnDesktop {
    // На Windows у cloud_firestore иногда ломается stream/query (platform-thread issue).
    // Для стабильности тянем контент через REST.
    return !kIsWeb && Platform.isWindows;
  }

  bool get _preferRestRead {
    // Фолбэк для iOS/Android: если Firebase нативно не поднялся
    // (например, отсутствует GoogleService-Info.plist), все равно читаем контент по REST.
    return _preferRestOnDesktop || _firestore == null;
  }

  // Categories
  Stream<List<Category>> getCategoriesStream() {
    if (_preferRestRead) {
      return Stream<int>.periodic(const Duration(seconds: 2), (i) => i)
          .asyncMap<List<Category>>((_) => getCategories())
          .distinct((a, b) => listEquals(a, b));
    }
    if (!_isInitialized || _firestore == null) {
      return Stream.error(Exception('Firebase Firestore not initialized'));
    }
    return _firestore!
        .collection('categories')
        .where('isVisible', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<List<Category>> getCategories() async {
    if (_preferRestRead) {
      try {
        final docs = await FirestoreRestService.listCollectionDocs('categories');
        return docs
            .map((m) => Category.fromFirestore(m, (m['id'] as String?) ?? ''))
            .where((c) => c.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      } catch (_) {
        return _getCategoriesFromServerApi();
      }
    }
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase Firestore not initialized');
    }
    try {
      final snapshot = await _firestore!
          .collection('categories')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .get();
      final result = snapshot.docs
          .map((doc) => Category.fromFirestore(doc.data(), doc.id))
          .toList();
      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}
    return _getCategoriesFromServerApi();
  }

  Future<void> updateCategoryOrders(List<Category> categories) async {
    if (!_isInitialized || _firestore == null) {
      return;
    }
    final batch = _firestore!.batch();
    for (final category in categories) {
      final docRef = _firestore!.collection('categories').doc(category.id);
      batch.update(docRef, {'order': category.order});
    }
    await batch.commit();
  }

  Future<Category?> getCategory(String id) async {
    if (!_isInitialized || _firestore == null) {
      return null;
    }
    try {
      final doc = await _firestore!.collection('categories').doc(id).get();
      if (doc.exists) {
        return Category.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      // Игнорируем ошибки
    }
    return null;
  }

  // Animals
  Stream<List<Animal>> getAnimalsStream(String categoryId) {
    if (_preferRestRead) {
      return Stream<int>.periodic(const Duration(seconds: 2), (i) => i)
          .asyncMap<List<Animal>>((_) => getAnimals(categoryId))
          .distinct((a, b) => listEquals(a, b));
    }
    if (!_isInitialized || _firestore == null) {
      return Stream.error(Exception('Firebase Firestore not initialized'));
    }
    return _firestore!
        .collection('categories')
        .doc(categoryId)
        .collection('animals')
        .where('isVisible', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Animal.fromFirestore(doc.data(), doc.id, categoryId))
            .toList());
  }

  Future<List<Animal>> getAnimals(String categoryId) async {
    if (_preferRestRead) {
      try {
        final docs = await FirestoreRestService.listCollectionDocs('categories/$categoryId/animals');
        return docs
            .map((m) => Animal.fromFirestore(m, (m['id'] as String?) ?? '', categoryId))
            .where((a) => a.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      } catch (_) {
        return _getAnimalsFromServerApi(categoryId);
      }
    }
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase Firestore not initialized');
    }
    try {
      final snapshot = await _firestore!
          .collection('categories')
          .doc(categoryId)
          .collection('animals')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .get();
      final result = snapshot.docs
          .map((doc) => Animal.fromFirestore(doc.data(), doc.id, categoryId))
          .toList();
      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}
    return _getAnimalsFromServerApi(categoryId);
  }

  Future<Animal?> getAnimal(String categoryId, String animalId) async {
    if (!_isInitialized || _firestore == null) {
      return null;
    }
    try {
      final doc = await _firestore!
          .collection('categories')
          .doc(categoryId)
          .collection('animals')
          .doc(animalId)
          .get();
      if (doc.exists) {
        return Animal.fromFirestore(doc.data()!, doc.id, categoryId);
      }
    } catch (e) {
      // Игнорируем ошибки
    }
    return null;
  }

  // Offers
  Future<List<Offer>> getOffers() async {
    if (!_isInitialized || _firestore == null) {
      return [];
    }
    try {
      final snapshot = await _firestore!
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => Offer.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ParentalTest>> getParentalTests() async {
    if (_preferRestRead) {
      final docs = await FirestoreRestService.listCollectionDocs('parental_tests');
      return docs
          .map((m) => ParentalTest.fromFirestore(m, (m['id'] as String?) ?? ''))
          .where((t) => t.isActive)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase Firestore not initialized');
    }
    final snapshot = await _firestore!
        .collection('parental_tests')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => ParentalTest.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<Category>> _getCategoriesFromServerApi() async {
    final uri = Uri.parse('$_contentBaseUrl/api/content/categories');
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Content categories API failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['categories'] as List<dynamic>? ?? const []);
    final categories = list
        .map((e) => e as Map<String, dynamic>)
        .map((m) => Category.fromFirestore(m, (m['id'] as String?) ?? ''))
        .where((c) => c.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  Future<List<Animal>> _getAnimalsFromServerApi(String categoryId) async {
    final safeCategoryId = Uri.encodeComponent(categoryId);
    final uri = Uri.parse('$_contentBaseUrl/api/content/categories/$safeCategoryId/animals');
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Content animals API failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['animals'] as List<dynamic>? ?? const []);
    final animals = list
        .map((e) => e as Map<String, dynamic>)
        .map((m) => Animal.fromFirestore(m, (m['id'] as String?) ?? '', categoryId))
        .where((a) => a.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return animals;
  }

  Future<Promotion?> getActivePromotion({required String deviceId}) async {
    final uri = Uri.parse(
      '$_analyticsBaseUrl/api/promotions/active?deviceId=${Uri.encodeQueryComponent(deviceId)}',
    );
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Active promotion request failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final promo = json['promotion'];
    if (promo == null) return null;
    return Promotion.fromJson(promo as Map<String, dynamic>);
  }

  // Storage
  Future<String> getDownloadUrl(String path) async {
    if (!_isInitialized || _storage == null) {
      throw Exception('Firebase Storage not initialized');
    }
    try {
      return await _storage!.ref(path).getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Analytics
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    final type = eventName == 'purchase_success' ? 'purchase' : eventName;
    final params = parameters ?? <String, dynamic>{};
    final uri = Uri.parse('$_analyticsBaseUrl/api/analytics/event');
    final payload = <String, dynamic>{'type': type, 'ts': DateTime.now().millisecondsSinceEpoch};
    if (params['categoryId'] != null) {
      payload['categoryId'] = params['categoryId'];
    }
    if (params['animalId'] != null) {
      payload['animalId'] = params['animalId'];
    }
    if (params['revenueRub'] != null) {
      payload['revenueRub'] = params['revenueRub'];
    }
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-analytics-key': _analyticsIngestKey,
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Analytics ingest failed: ${res.statusCode} ${res.body}');
    }
  }
}
