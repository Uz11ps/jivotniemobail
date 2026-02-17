import 'package:equatable/equatable.dart';

class ParentalTest extends Equatable {
  final String id;
  final int order;
  final bool isActive;
  final int left;
  final int right;
  final String operator;
  final List<int> answers;
  final int correctAnswer;

  const ParentalTest({
    required this.id,
    required this.order,
    required this.isActive,
    required this.left,
    required this.right,
    required this.operator,
    required this.answers,
    required this.correctAnswer,
  });

  factory ParentalTest.fromFirestore(Map<String, dynamic> data, String id) {
    final rawAnswers = (data['answers'] as List<dynamic>? ?? const []);
    return ParentalTest(
      id: id,
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      left: (data['left'] as num?)?.toInt() ?? 0,
      right: (data['right'] as num?)?.toInt() ?? 0,
      operator: (data['operator'] as String?) ?? '+',
      answers: rawAnswers.map((e) => (e as num).toInt()).toList(),
      correctAnswer: (data['correctAnswer'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, order, isActive, left, right, operator, answers, correctAnswer];
}

