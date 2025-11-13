import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { mcq, tf, image, numeric, poll, order }

class QuizQuestion {
  final String id;
  final int index;
  final QuestionType type;
  final String text;
  final String? media; // image path/URL
  final List<dynamic> options; // strings or maps (for image/order)
  final int? correctIndex;
  final List<int>? correctIndices; // future multi-select
  final num? numericAnswer;
  final List<dynamic>? orderSolution; // expected order
  final int timeLimitSeconds;
  final String pointsMode; // future extension

  QuizQuestion({
    required this.id,
    required this.index,
    required this.type,
    required this.text,
    required this.media,
    required this.options,
    required this.correctIndex,
    required this.correctIndices,
    required this.numericAnswer,
    required this.orderSolution,
    required this.timeLimitSeconds,
    required this.pointsMode,
  });

  factory QuizQuestion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return QuizQuestion(
      id: doc.id,
      index: (d['index'] as num).toInt(),
      type: _parseType(d['type'] as String),
      text: (d['text'] as String?) ?? '',
      media: d['media'] as String?,
      options: (d['options'] as List?) ?? const [],
      correctIndex: (d['correctIndex'] as num?)?.toInt(),
      correctIndices: (d['correctIndices'] as List?)?.cast<int>(),
      numericAnswer: d['numericAnswer'] as num?,
      orderSolution: (d['orderSolution'] as List?),
      timeLimitSeconds: (d['timeLimitSeconds'] as num? ?? 20).toInt(),
      pointsMode: (d['pointsMode'] as String?) ?? 'standard',
    );
  }

  static QuestionType _parseType(String raw) {
    switch (raw) {
      case 'mcq':
        return QuestionType.mcq;
      case 'tf':
        return QuestionType.tf;
      case 'image':
        return QuestionType.image;
      case 'numeric':
        return QuestionType.numeric;
      case 'poll':
        return QuestionType.poll;
      case 'order':
        return QuestionType.order;
      default:
        return QuestionType.mcq;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'text': text,
      if (media != null) 'media': media,
      'options': options,
      if (correctIndex != null) 'correctIndex': correctIndex,
      if (correctIndices != null) 'correctIndices': correctIndices,
      if (numericAnswer != null) 'numericAnswer': numericAnswer,
      if (orderSolution != null) 'orderSolution': orderSolution,
      'timeLimitSeconds': timeLimitSeconds,
      'pointsMode': pointsMode,
    };
  }
}
