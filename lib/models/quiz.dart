import 'package:cloud_firestore/cloud_firestore.dart';

class QuizMeta {
  final String id;
  final String title;
  final String? description;
  final int totalQuestions;
  final String createdBy;
  final DateTime createdAt;
  final String visibility; // private|public
  final String gameMode; // standard|uniqueAnswer|truthOrDare|hrissa

  QuizMeta({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.createdBy,
    required this.createdAt,
    required this.visibility,
    this.gameMode = 'standard',
  });

  factory QuizMeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return QuizMeta(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Untitled Quiz',
      description: d['description'] as String?,
      totalQuestions: (d['totalQuestions'] as num? ?? 0).toInt(),
      createdBy: (d['createdBy'] as String?) ?? 'unknown',
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      visibility: (d['visibility'] as String?) ?? 'private',
      gameMode: (d['gameMode'] as String?) ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'totalQuestions': totalQuestions,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'visibility': visibility,
    'gameMode': gameMode,
  };
}
