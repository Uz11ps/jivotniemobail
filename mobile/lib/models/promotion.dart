import 'package:equatable/equatable.dart';
import 'category.dart';

class Promotion extends Equatable {
  final String id;
  final int order;
  final bool isActive;
  final LocalizedString title;
  final LocalizedString message;
  final int discountPercent;
  final String target;
  final List<String> deviceIds;
  final String? startsAt;
  final String? endsAt;

  const Promotion({
    required this.id,
    required this.order,
    required this.isActive,
    required this.title,
    required this.message,
    required this.discountPercent,
    required this.target,
    required this.deviceIds,
    this.startsAt,
    this.endsAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> data) {
    final ids = (data['deviceIds'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return Promotion(
      id: (data['id'] as String?) ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      title: LocalizedString.fromMap((data['title'] as Map<String, dynamic>?) ?? const {}),
      message: LocalizedString.fromMap((data['message'] as Map<String, dynamic>?) ?? const {}),
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
      target: (data['target'] as String?) ?? 'all',
      deviceIds: ids,
      startsAt: data['startsAt'] as String?,
      endsAt: data['endsAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        order,
        isActive,
        title,
        message,
        discountPercent,
        target,
        deviceIds,
        startsAt,
        endsAt,
      ];
}

