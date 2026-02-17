import 'package:equatable/equatable.dart';
import 'category.dart';

class Offer extends Equatable {
  final String id;
  final LocalizedString title;
  final bool isActive;
  final String? primaryProductId;
  final List<OfferItem> items;
  final List<String> heroAssets;

  const Offer({
    required this.id,
    required this.title,
    required this.isActive,
    this.primaryProductId,
    required this.items,
    required this.heroAssets,
  });

  factory Offer.fromFirestore(Map<String, dynamic> data, String id) {
    return Offer(
      id: id,
      title: LocalizedString.fromMap(data['title'] ?? {}),
      isActive: data['isActive'] ?? false,
      primaryProductId: data['primaryProductId'],
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OfferItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      heroAssets: List<String>.from(data['heroAssets'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.toMap(),
      'isActive': isActive,
      'primaryProductId': primaryProductId,
      'items': items.map((item) => item.toMap()).toList(),
      'heroAssets': heroAssets,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        isActive,
        primaryProductId,
        items,
        heroAssets,
      ];
}

class OfferItem extends Equatable {
  final String productId;
  final String type; // 'category' or 'animal'

  const OfferItem({
    required this.productId,
    required this.type,
  });

  factory OfferItem.fromMap(Map<String, dynamic> map) {
    return OfferItem(
      productId: map['productId'] ?? '',
      type: map['type'] ?? 'category',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [productId, type];
}
