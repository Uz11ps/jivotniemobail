import 'package:equatable/equatable.dart';
import 'category.dart';

class Animal extends Equatable {
  final String id;
  final String categoryId;
  final LocalizedString name;
  final LocalizedString? topText;
  final int order;
  final bool isVisible;
  final String? bgAssetPath;
  final String? bgVideoAssetPath;
  final String? previewAssetPath;
  final String? soundAssetPath;
  final Map<String, String>? voiceAssetPath;
  final String? animationAssetPath;

  const Animal({
    required this.id,
    required this.categoryId,
    required this.name,
    this.topText,
    required this.order,
    required this.isVisible,
    this.bgAssetPath,
    this.bgVideoAssetPath,
    this.previewAssetPath,
    this.soundAssetPath,
    this.voiceAssetPath,
    this.animationAssetPath,
  });

  factory Animal.fromFirestore(Map<String, dynamic> data, String id, String categoryId) {
    return Animal(
      id: id,
      categoryId: categoryId,
      name: LocalizedString.fromMap(data['name'] ?? {}),
      topText: data['topText'] != null ? LocalizedString.fromMap(data['topText'] ?? {}) : null,
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true,
      bgAssetPath: data['bgAssetPath'],
      bgVideoAssetPath: data['bgVideoAssetPath'],
      previewAssetPath: data['previewAssetPath'],
      soundAssetPath: data['soundAssetPath'],
      voiceAssetPath: (data['voiceAssetPath'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      animationAssetPath: data['animationAssetPath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.toMap(),
      'topText': topText?.toMap(),
      'order': order,
      'isVisible': isVisible,
      'bgAssetPath': bgAssetPath,
      'bgVideoAssetPath': bgVideoAssetPath,
      'previewAssetPath': previewAssetPath,
      'soundAssetPath': soundAssetPath,
      'voiceAssetPath': voiceAssetPath,
      'animationAssetPath': animationAssetPath,
    };
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        topText,
        order,
        isVisible,
        bgAssetPath,
        bgVideoAssetPath,
        previewAssetPath,
        soundAssetPath,
        voiceAssetPath,
        animationAssetPath,
      ];
}
