import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final LocalizedString title;
  final int order;
  final bool isVisible;
  final bool isPaid;
  final String? iapProductId;
  final String tabIconAssetPath;
  final String? heroImageAssetPath;
  final String? heroVideoAssetPath;
  final String? backgroundColorHex;

  const Category({
    required this.id,
    required this.title,
    required this.order,
    required this.isVisible,
    required this.isPaid,
    this.iapProductId,
    required this.tabIconAssetPath,
    this.heroImageAssetPath,
    this.heroVideoAssetPath,
    this.backgroundColorHex,
  });

  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      title: LocalizedString.fromMap(data['title'] ?? {}),
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true,
      isPaid: data['isPaid'] ?? false,
      iapProductId: data['iapProductId'],
      tabIconAssetPath: data['tabIconAssetPath'] ?? '',
      heroImageAssetPath: data['heroImageAssetPath'],
      heroVideoAssetPath: data['heroVideoAssetPath'],
      backgroundColorHex: data['backgroundColorHex'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.toMap(),
      'order': order,
      'isVisible': isVisible,
      'isPaid': isPaid,
      'iapProductId': iapProductId,
      'tabIconAssetPath': tabIconAssetPath,
      'heroImageAssetPath': heroImageAssetPath,
      'heroVideoAssetPath': heroVideoAssetPath,
      'backgroundColorHex': backgroundColorHex,
    };
  }

  Category copyWith({
    String? id,
    LocalizedString? title,
    int? order,
    bool? isVisible,
    bool? isPaid,
    String? iapProductId,
    String? tabIconAssetPath,
    String? heroImageAssetPath,
    String? heroVideoAssetPath,
    String? backgroundColorHex,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      isPaid: isPaid ?? this.isPaid,
      iapProductId: iapProductId ?? this.iapProductId,
      tabIconAssetPath: tabIconAssetPath ?? this.tabIconAssetPath,
      heroImageAssetPath: heroImageAssetPath ?? this.heroImageAssetPath,
      heroVideoAssetPath: heroVideoAssetPath ?? this.heroVideoAssetPath,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        order,
        isVisible,
        isPaid,
        iapProductId,
        tabIconAssetPath,
        heroImageAssetPath,
        heroVideoAssetPath,
        backgroundColorHex,
      ];
}

class LocalizedString extends Equatable {
  final String ru;
  final String en;

  const LocalizedString({
    required this.ru,
    required this.en,
  });

  factory LocalizedString.fromMap(Map<String, dynamic> map) {
    return LocalizedString(
      ru: map['ru'] ?? '',
      en: map['en'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ru': ru,
      'en': en,
    };
  }

  String getLocalized(String locale) {
    return locale == 'ru' ? ru : en;
  }

  @override
  List<Object?> get props => [ru, en];
}
