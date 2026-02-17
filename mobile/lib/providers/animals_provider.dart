import 'package:flutter/foundation.dart';
import '../models/animal.dart';
import '../services/firebase_service.dart';

class AnimalsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Map<String, List<Animal>> _animalsByCategory = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errors = {};

  List<Animal> getAnimals(String categoryId) {
    return _animalsByCategory[categoryId] ?? [];
  }

  bool isLoading(String categoryId) {
    return _loadingStates[categoryId] ?? false;
  }

  String? getError(String categoryId) {
    return _errors[categoryId];
  }

  Future<void> loadAnimals(String categoryId) async {
    if (_loadingStates[categoryId] == true) {
      return;
    }
    _loadingStates[categoryId] = true;
    _errors[categoryId] = null;
    notifyListeners();

    try {
      final animals = await _firebaseService.getAnimals(categoryId);
      _animalsByCategory[categoryId] = animals;
      _errors[categoryId] = null;
    } catch (e) {
      _errors[categoryId] = e.toString();
      if (kDebugMode) {
        print('Error loading animals: $e');
      }
    } finally {
      _loadingStates[categoryId] = false;
      notifyListeners();
    }
  }

  Animal? getAnimalById(String categoryId, String animalId) {
    final animals = _animalsByCategory[categoryId];
    if (animals == null) return null;
    try {
      return animals.firstWhere((animal) => animal.id == animalId);
    } catch (e) {
      return null;
    }
  }
}
