import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSession {
  final String id;
  final String quizId;
  final String hostId;
  final String pin;
  final String status; // lobby|running|ended
  final int currentQuestionIndex;
  final String questionState; // intro|answering|reveal|transition
  final DateTime? questionStartAt;
  final DateTime? questionEndAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizSession({
    required this.id,
    required this.quizId,
    required this.hostId,
    required this.pin,
    required this.status,
    required this.currentQuestionIndex,
    required this.questionState,
    required this.questionStartAt,
    required this.questionEndAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return QuizSession(
      id: doc.id,
      quizId: (d['quizId'] as String?) ?? '',
      hostId: (d['hostId'] as String?) ?? '',
      pin: (d['pin'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'lobby',
      currentQuestionIndex: (d['currentQuestionIndex'] as num? ?? -1).toInt(),
      questionState: (d['questionState'] as String?) ?? 'intro',
      questionStartAt: (d['questionStartAt'] as Timestamp?)?.toDate(),
      questionEndAt: (d['questionEndAt'] as Timestamp?)?.toDate(),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          (d['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
