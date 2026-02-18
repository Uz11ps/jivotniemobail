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
  static const String _repoVideoBaseUrl =
      'https://raw.githubusercontent.com/Uz11ps/jivotniemobail/main/img';

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
      final poll = _preferRestOnDesktop
          ? const Duration(seconds: 2)
          : const Duration(seconds: 30);
      return _pollCategoriesStream(poll)
          .distinct((a, b) => listEquals(a, b));
    }
    if (!_isInitialized || _firestore == null) {
      return Stream.error(Exception('Firebase Firestore not initialized'));
    }
    return _firestore!
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc.data(), doc.id))
            .where((c) => c.isVisible)
            .toList());
  }

  Future<List<Category>> getCategories() async {
    if (_preferRestRead) {
      if (_firestore == null) {
        // Без Firebase на iOS стартуем мгновенно с локального набора.
        return _localFallbackCategories();
      }
      try {
        final docs = await FirestoreRestService.listCollectionDocs('categories');
        return docs
            .map((m) => Category.fromFirestore(m, (m['id'] as String?) ?? ''))
            .where((c) => c.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      } catch (_) {
        try {
          return await _getCategoriesFromServerApi();
        } catch (_) {
          return _localFallbackCategories();
        }
      }
    }
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase Firestore not initialized');
    }
    try {
      final snapshot = await _firestore!
          .collection('categories')
          .orderBy('order')
          .get();
      final result = snapshot.docs
          .map((doc) => Category.fromFirestore(doc.data(), doc.id))
          .where((c) => c.isVisible)
          .toList();
      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}
    try {
      return await _getCategoriesFromServerApi();
    } catch (_) {
      return _localFallbackCategories();
    }
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
      final poll = _preferRestOnDesktop
          ? const Duration(seconds: 2)
          : const Duration(seconds: 30);
      return _pollAnimalsStream(categoryId, poll)
          .distinct((a, b) => listEquals(a, b));
    }
    if (!_isInitialized || _firestore == null) {
      return Stream.error(Exception('Firebase Firestore not initialized'));
    }
    return _firestore!
        .collection('categories')
        .doc(categoryId)
        .collection('animals')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Animal.fromFirestore(doc.data(), doc.id, categoryId))
            .where((a) => a.isVisible)
            .toList());
  }

  Future<List<Animal>> getAnimals(String categoryId) async {
    if (_preferRestRead) {
      if (_firestore == null) {
        // Без Firebase на iOS стартуем мгновенно с локального набора.
        return _localFallbackAnimals(categoryId);
      }
      try {
        final docs = await FirestoreRestService.listCollectionDocs('categories/$categoryId/animals');
        return docs
            .map((m) => Animal.fromFirestore(m, (m['id'] as String?) ?? '', categoryId))
            .where((a) => a.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      } catch (_) {
        try {
          return await _getAnimalsFromServerApi(categoryId);
        } catch (_) {
          return _localFallbackAnimals(categoryId);
        }
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
          .orderBy('order')
          .get();
      final result = snapshot.docs
          .map((doc) => Animal.fromFirestore(doc.data(), doc.id, categoryId))
          .where((a) => a.isVisible)
          .toList();
      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}
    try {
      return await _getAnimalsFromServerApi(categoryId);
    } catch (_) {
      return _localFallbackAnimals(categoryId);
    }
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
    final res = await http.get(uri).timeout(const Duration(seconds: 4));
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

  Stream<List<Category>> _pollCategoriesStream(Duration poll) async* {
    // Первый результат нужен сразу, без ожидания периода.
    if (_firestore == null) {
      yield _localFallbackCategories();
      yield* Stream<int>.periodic(poll, (i) => i).asyncMap<List<Category>>((_) async {
        try {
          return await _getCategoriesFromServerApi();
        } catch (_) {
          return _localFallbackCategories();
        }
      });
      return;
    }
    yield await getCategories();
    yield* Stream<int>.periodic(poll, (i) => i).asyncMap<List<Category>>((_) => getCategories());
  }

  Stream<List<Animal>> _pollAnimalsStream(String categoryId, Duration poll) async* {
    // Первый результат нужен сразу, без ожидания периода.
    if (_firestore == null) {
      yield _localFallbackAnimals(categoryId);
      yield* Stream<int>.periodic(poll, (i) => i).asyncMap<List<Animal>>((_) async {
        try {
          return await _getAnimalsFromServerApi(categoryId);
        } catch (_) {
          return _localFallbackAnimals(categoryId);
        }
      });
      return;
    }
    yield await getAnimals(categoryId);
    yield* Stream<int>.periodic(poll, (i) => i).asyncMap<List<Animal>>((_) => getAnimals(categoryId));
  }

  Future<List<Animal>> _getAnimalsFromServerApi(String categoryId) async {
    final safeCategoryId = Uri.encodeComponent(categoryId);
    final uri = Uri.parse('$_contentBaseUrl/api/content/categories/$safeCategoryId/animals');
    final res = await http.get(uri).timeout(const Duration(seconds: 4));
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

  List<Category> _localFallbackCategories() {
    return const [
      Category(
        id: 'pets',
        title: LocalizedString(ru: 'Питомцы', en: 'Pets'),
        order: 0,
        isVisible: true,
        isPaid: false,
        iapProductId: null,
        tabIconAssetPath: '',
      ),
      Category(
        id: 'farm',
        title: LocalizedString(ru: 'Ферма', en: 'Farm'),
        order: 1,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.farm',
        tabIconAssetPath: '',
      ),
      Category(
        id: 'forest',
        title: LocalizedString(ru: 'Лес', en: 'Forest'),
        order: 2,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.forest',
        tabIconAssetPath: '',
      ),
      Category(
        id: 'jungle',
        title: LocalizedString(ru: 'Джунгли', en: 'Jungle'),
        order: 3,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.jungle',
        tabIconAssetPath: '',
      ),
    ];
  }

  List<Animal> _localFallbackAnimals(String categoryId) {
    if (categoryId == 'pets') {
      return [
        Animal(
          id: 'cat',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Кот', en: 'Cat'),
          topText: const LocalizedString(ru: 'Кот/кошка', en: 'Cat'),
          order: 0,
          isVisible: true,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Cat.mp4',
        ),
        Animal(
          id: 'rabbit',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Кролик', en: 'Rabbit'),
          topText: const LocalizedString(ru: 'Кролик', en: 'Rabbit'),
          order: 1,
          isVisible: true,
        ),
        Animal(
          id: 'frog',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Лягушка', en: 'Frog'),
          topText: const LocalizedString(ru: 'Лягушка', en: 'Frog'),
          order: 2,
          isVisible: true,
        ),
        Animal(
          id: 'guinea',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Морская свинка', en: 'Guinea Pig'),
          topText: const LocalizedString(ru: 'Морская свинка', en: 'Guinea pig'),
          order: 3,
          isVisible: true,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Guinea%20Pig.mp4',
        ),
        Animal(
          id: 'turtle',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Черепаха', en: 'Turtle'),
          topText: const LocalizedString(ru: 'Черепаха', en: 'Turtle'),
          order: 4,
          isVisible: true,
        ),
        Animal(
          id: 'dog',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Собака', en: 'Dog'),
          topText: const LocalizedString(ru: 'Собака', en: 'Dog'),
          order: 5,
          isVisible: true,
        ),
        Animal(
          id: 'mouse',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Мышка', en: 'Mouse'),
          topText: const LocalizedString(ru: 'Мышка', en: 'Mouse'),
          order: 6,
          isVisible: true,
        ),
        Animal(
          id: 'hamster',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Хомяк', en: 'Hamster'),
          topText: const LocalizedString(ru: 'Хомяк', en: 'Hamster'),
          order: 7,
          isVisible: true,
        ),
        Animal(
          id: 'parrot',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Попугай', en: 'Parrot'),
          topText: const LocalizedString(ru: 'Попугай', en: 'Parrot'),
          order: 8,
          isVisible: true,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Parrot.mp4',
        ),
        Animal(
          id: 'ferret',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Хорек', en: 'Ferret'),
          topText: const LocalizedString(ru: 'Хорек', en: 'Ferret'),
          order: 9,
          isVisible: true,
          bgVideoAssetPath: '$_repoVideoBaseUrl/%D0%A1hinchilla.mp4',
        ),
        Animal(
          id: 'snail',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Улитка', en: 'Snail'),
          topText: const LocalizedString(ru: 'Улитка', en: 'Snail'),
          order: 10,
          isVisible: true,
        ),
        Animal(
          id: 'white_mouse',
          categoryId: 'pets',
          name: const LocalizedString(ru: 'Белая мышь', en: 'White mouse'),
          topText: const LocalizedString(ru: 'Белая мышь', en: 'White mouse'),
          order: 11,
          isVisible: true,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Guinea%20Pig%202.mp4',
        ),
      ];
    }
    if (categoryId == 'farm') {
      return const [
        Animal(
          id: 'cow',
          categoryId: 'farm',
          name: LocalizedString(ru: 'Корова', en: 'Cow'),
          topText: LocalizedString(ru: 'Корова', en: 'Cow'),
          order: 0,
          isVisible: true,
        ),
        Animal(
          id: 'pig',
          categoryId: 'farm',
          name: LocalizedString(ru: 'Свинья', en: 'Pig'),
          topText: LocalizedString(ru: 'Свинья', en: 'Pig'),
          order: 1,
          isVisible: true,
        ),
        Animal(
          id: 'goat',
          categoryId: 'farm',
          name: LocalizedString(ru: 'Коза', en: 'Goat'),
          topText: LocalizedString(ru: 'Коза', en: 'Goat'),
          order: 2,
          isVisible: true,
        ),
      ];
    }
    return const [];
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
