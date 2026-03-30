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
        return _mergeCategoriesWithFallback(const []);
      }
      try {
        final docs = await FirestoreRestService.listCollectionDocs('categories');
        final categories = docs
            .map((m) => Category.fromFirestore(m, (m['id'] as String?) ?? ''))
            .where((c) => c.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return _mergeCategoriesWithFallback(categories);
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
        return _mergeCategoriesWithFallback(result);
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
        final result = docs
            .map((m) => Animal.fromFirestore(m, (m['id'] as String?) ?? '', categoryId))
            .where((a) => a.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        if (result.isNotEmpty) {
          return result;
        }
        return await _getAnimalsFromServerApi(categoryId);
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
      try {
        final docs = await FirestoreRestService.listCollectionDocs('parental_tests');
        final tests = docs
            .map((m) => ParentalTest.fromFirestore(m, (m['id'] as String?) ?? ''))
            .where((t) => t.isActive)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        if (tests.isNotEmpty) return tests;
      } catch (_) {}
      return _localFallbackParentalTests();
    }
    if (!_isInitialized || _firestore == null) {
      return _localFallbackParentalTests();
    }
    try {
      final snapshot = await _firestore!
          .collection('parental_tests')
          .orderBy('order')
          .get();
      final tests = snapshot.docs
          .map((doc) => ParentalTest.fromFirestore(doc.data(), doc.id))
          .where((t) => t.isActive)
          .toList();
      if (tests.isNotEmpty) return tests;
    } catch (_) {}
    return _localFallbackParentalTests();
  }

  List<ParentalTest> _localFallbackParentalTests() {
    return const [
      ParentalTest(
        id: 'local_1',
        order: 0,
        isActive: true,
        left: 2,
        right: 7,
        operator: '+',
        answers: [8, 5, 9, 10],
        correctAnswer: 9,
      ),
      ParentalTest(
        id: 'local_2',
        order: 1,
        isActive: true,
        left: 5,
        right: 3,
        operator: '+',
        answers: [6, 7, 8, 9],
        correctAnswer: 8,
      ),
    ];
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
    return _mergeCategoriesWithFallback(categories);
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

  List<Category> _mergeCategoriesWithFallback(List<Category> source) {
    final fallback = _localFallbackCategories();
    final byId = <String, Category>{
      for (final category in fallback) category.id: category,
    };
    for (final category in source) {
      byId[category.id] = category.copyWith(
        backgroundColorHex: category.backgroundColorHex ?? byId[category.id]?.backgroundColorHex,
      );
    }
    final merged = byId.values.where((category) => category.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return merged;
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
    if (animals.isNotEmpty) {
      return animals;
    }
    return _localFallbackAnimals(categoryId);
  }

  Future<List<Map<String, dynamic>>> getOnboardingSlides() async {
    try {
      final uri = Uri.parse('$_contentBaseUrl/api/content/onboarding');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Content onboarding API failed: ${res.statusCode}');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (json['slides'] as List<dynamic>? ?? const []);
      return list
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .where((m) => (m['isActive'] as bool?) ?? true)
          .toList()
        ..sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
    } catch (_) {
      return const [];
    }
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
        backgroundColorHex: '#66AEF8',
      ),
      Category(
        id: 'farm',
        title: LocalizedString(ru: 'Ферма', en: 'Farm'),
        order: 1,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.farm',
        tabIconAssetPath: '',
        backgroundColorHex: '#F5A623',
      ),
      Category(
        id: 'forest',
        title: LocalizedString(ru: 'Лес', en: 'Forest'),
        order: 2,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.forest',
        tabIconAssetPath: '',
        backgroundColorHex: '#4C8C2B',
      ),
      Category(
        id: 'savannah',
        title: LocalizedString(ru: 'Саванна', en: 'Savannah'),
        order: 3,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.savannah',
        tabIconAssetPath: '',
        backgroundColorHex: '#F7D15E',
      ),
      Category(
        id: 'pond',
        title: LocalizedString(ru: 'Пруд', en: 'Pond'),
        order: 4,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.pond',
        tabIconAssetPath: '',
        backgroundColorHex: '#86D6D9',
      ),
      Category(
        id: 'jungle',
        title: LocalizedString(ru: 'Джунгли', en: 'Jungle'),
        order: 5,
        isVisible: true,
        isPaid: true,
        iapProductId: 'com.detiiosjivotnie.jungle',
        tabIconAssetPath: '',
        backgroundColorHex: '#7FC64F',
      ),
    ];
  }

  List<Animal> _localFallbackAnimals(String categoryId) {
    Animal animal({
      required String id,
      required String categoryId,
      required String ru,
      required String en,
      required int order,
      String? bgVideoAssetPath,
    }) {
      return Animal(
        id: id,
        categoryId: categoryId,
        name: LocalizedString(ru: ru, en: en),
        topText: LocalizedString(ru: ru, en: en),
        order: order,
        isVisible: true,
        bgVideoAssetPath: bgVideoAssetPath,
      );
    }

    if (categoryId == 'pets') {
      return [
        animal(id: 'cat', categoryId: 'pets', ru: 'Кот', en: 'Cat', order: 0, bgVideoAssetPath: '$_repoVideoBaseUrl/Cat.mp4'),
        animal(id: 'rabbit', categoryId: 'pets', ru: 'Кролик', en: 'Rabbit', order: 1),
        animal(id: 'frog', categoryId: 'pets', ru: 'Лягушка', en: 'Frog', order: 2),
        animal(
          id: 'guinea',
          categoryId: 'pets',
          ru: 'Морская свинка',
          en: 'Guinea Pig',
          order: 3,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Guinea%20Pig.mp4',
        ),
        animal(id: 'turtle', categoryId: 'pets', ru: 'Черепаха', en: 'Turtle', order: 4),
        animal(id: 'dog', categoryId: 'pets', ru: 'Собака', en: 'Dog', order: 5),
        animal(id: 'mouse', categoryId: 'pets', ru: 'Мышка', en: 'Mouse', order: 6),
        animal(id: 'hamster', categoryId: 'pets', ru: 'Хомяк', en: 'Hamster', order: 7),
        animal(id: 'parrot', categoryId: 'pets', ru: 'Попугай', en: 'Parrot', order: 8, bgVideoAssetPath: '$_repoVideoBaseUrl/Parrot.mp4'),
        animal(id: 'ferret', categoryId: 'pets', ru: 'Хорек', en: 'Ferret', order: 9, bgVideoAssetPath: '$_repoVideoBaseUrl/%D0%A1hinchilla.mp4'),
        animal(id: 'snail', categoryId: 'pets', ru: 'Улитка', en: 'Snail', order: 10),
        animal(
          id: 'white_mouse',
          categoryId: 'pets',
          ru: 'Белая мышь',
          en: 'White mouse',
          order: 11,
          bgVideoAssetPath: '$_repoVideoBaseUrl/Guinea%20Pig%202.mp4',
        ),
      ];
    }
    if (categoryId == 'farm') {
      return [
        animal(id: 'horse', categoryId: 'farm', ru: 'Лошадь', en: 'Horse', order: 0),
        animal(id: 'pig', categoryId: 'farm', ru: 'Свинья', en: 'Pig', order: 1),
        animal(id: 'cow', categoryId: 'farm', ru: 'Корова', en: 'Cow', order: 2),
        animal(id: 'chicken', categoryId: 'farm', ru: 'Курица', en: 'Chicken', order: 3),
        animal(id: 'sheep', categoryId: 'farm', ru: 'Овца', en: 'Sheep', order: 4),
        animal(id: 'goat', categoryId: 'farm', ru: 'Коза', en: 'Goat', order: 5),
        animal(id: 'ostrich', categoryId: 'farm', ru: 'Страус', en: 'Ostrich', order: 6),
        animal(id: 'duck', categoryId: 'farm', ru: 'Утка', en: 'Duck', order: 7),
        animal(id: 'deer', categoryId: 'farm', ru: 'Олень', en: 'Deer', order: 8),
        animal(id: 'bee', categoryId: 'farm', ru: 'Пчела', en: 'Bee', order: 9),
        animal(id: 'camel', categoryId: 'farm', ru: 'Верблюд', en: 'Camel', order: 10),
        animal(id: 'lamb', categoryId: 'farm', ru: 'Ягненок', en: 'Lamb', order: 11),
      ];
    }
    if (categoryId == 'forest') {
      return [
        animal(id: 'bear', categoryId: 'forest', ru: 'Медведь', en: 'Bear', order: 0),
        animal(id: 'wolf', categoryId: 'forest', ru: 'Волк', en: 'Wolf', order: 1),
        animal(id: 'fox', categoryId: 'forest', ru: 'Лиса', en: 'Fox', order: 2),
        animal(id: 'owl', categoryId: 'forest', ru: 'Сова', en: 'Owl', order: 3),
        animal(id: 'squirrel', categoryId: 'forest', ru: 'Белка', en: 'Squirrel', order: 4),
        animal(id: 'woodpecker', categoryId: 'forest', ru: 'Дятел', en: 'Woodpecker', order: 5),
        animal(id: 'hedgehog', categoryId: 'forest', ru: 'Еж', en: 'Hedgehog', order: 6),
        animal(id: 'deer', categoryId: 'forest', ru: 'Олень', en: 'Deer', order: 7),
        animal(id: 'sparrow', categoryId: 'forest', ru: 'Птичка', en: 'Bird', order: 8),
        animal(id: 'beaver', categoryId: 'forest', ru: 'Бобр', en: 'Beaver', order: 9),
        animal(id: 'crow', categoryId: 'forest', ru: 'Ворон', en: 'Crow', order: 10),
        animal(id: 'ant', categoryId: 'forest', ru: 'Муравей', en: 'Ant', order: 11),
      ];
    }
    if (categoryId == 'savannah') {
      return [
        animal(id: 'lion', categoryId: 'savannah', ru: 'Лев', en: 'Lion', order: 0),
        animal(id: 'elephant', categoryId: 'savannah', ru: 'Слон', en: 'Elephant', order: 1),
        animal(id: 'leopard', categoryId: 'savannah', ru: 'Леопард', en: 'Leopard', order: 2),
        animal(id: 'rhino', categoryId: 'savannah', ru: 'Носорог', en: 'Rhino', order: 3),
        animal(id: 'giraffe', categoryId: 'savannah', ru: 'Жираф', en: 'Giraffe', order: 4),
        animal(id: 'zebra', categoryId: 'savannah', ru: 'Зебра', en: 'Zebra', order: 5),
        animal(id: 'warthog', categoryId: 'savannah', ru: 'Бородавочник', en: 'Warthog', order: 6),
        animal(id: 'meerkat', categoryId: 'savannah', ru: 'Сурикат', en: 'Meerkat', order: 7),
        animal(id: 'chimpanzee', categoryId: 'savannah', ru: 'Шимпанзе', en: 'Chimpanzee', order: 8),
        animal(id: 'vulture', categoryId: 'savannah', ru: 'Гриф', en: 'Vulture', order: 9),
        animal(id: 'hippo', categoryId: 'savannah', ru: 'Бегемот', en: 'Hippo', order: 10),
        animal(id: 'buffalo', categoryId: 'savannah', ru: 'Буйвол', en: 'Buffalo', order: 11),
      ];
    }
    if (categoryId == 'pond') {
      return [
        animal(id: 'dragonfly', categoryId: 'pond', ru: 'Стрекоза', en: 'Dragonfly', order: 0),
        animal(id: 'crayfish', categoryId: 'pond', ru: 'Рак', en: 'Crayfish', order: 1),
        animal(id: 'shell', categoryId: 'pond', ru: 'Ракушка', en: 'Shell', order: 2),
        animal(id: 'newt', categoryId: 'pond', ru: 'Тритон', en: 'Newt', order: 3),
        animal(id: 'frog', categoryId: 'pond', ru: 'Лягушка', en: 'Frog', order: 4),
        animal(id: 'beetle', categoryId: 'pond', ru: 'Жук', en: 'Beetle', order: 5),
        animal(id: 'ant', categoryId: 'pond', ru: 'Муравей', en: 'Ant', order: 6),
        animal(id: 'duckling', categoryId: 'pond', ru: 'Утенок', en: 'Duckling', order: 7),
        animal(id: 'heron', categoryId: 'pond', ru: 'Цапля', en: 'Heron', order: 8),
        animal(id: 'fish', categoryId: 'pond', ru: 'Рыба', en: 'Fish', order: 9),
        animal(id: 'crocodile', categoryId: 'pond', ru: 'Крокодил', en: 'Crocodile', order: 10),
        animal(id: 'butterfly', categoryId: 'pond', ru: 'Бабочка', en: 'Butterfly', order: 11),
      ];
    }
    if (categoryId == 'jungle') {
      return [
        animal(id: 'leopard', categoryId: 'jungle', ru: 'Леопард', en: 'Leopard', order: 0),
        animal(id: 'sloth', categoryId: 'jungle', ru: 'Ленивец', en: 'Sloth', order: 1),
        animal(id: 'lizard', categoryId: 'jungle', ru: 'Ящерица', en: 'Lizard', order: 2),
        animal(id: 'crocodile', categoryId: 'jungle', ru: 'Крокодил', en: 'Crocodile', order: 3),
        animal(id: 'capybara', categoryId: 'jungle', ru: 'Капибара', en: 'Capybara', order: 4),
        animal(id: 'anteater', categoryId: 'jungle', ru: 'Муравьед', en: 'Anteater', order: 5),
        animal(id: 'monkey', categoryId: 'jungle', ru: 'Обезьяна', en: 'Monkey', order: 6),
        animal(id: 'tiger', categoryId: 'jungle', ru: 'Тигр', en: 'Tiger', order: 7),
        animal(id: 'bird', categoryId: 'jungle', ru: 'Птица', en: 'Bird', order: 8),
        animal(id: 'mantis', categoryId: 'jungle', ru: 'Богомол', en: 'Mantis', order: 9),
        animal(id: 'chameleon', categoryId: 'jungle', ru: 'Хамелеон', en: 'Chameleon', order: 10),
        animal(id: 'panther', categoryId: 'jungle', ru: 'Пантера', en: 'Panther', order: 11),
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
