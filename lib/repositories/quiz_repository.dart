import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:lamaplay/models/question.dart';

class QuizRepository {
  final _db = FirebaseFirestore.instance;

  Future<QuizMeta?> getQuiz(String quizId) async {
    final snap = await _db.collection('quizzes').doc(quizId).get();
    if (!snap.exists) return null;
    return QuizMeta.fromDoc(snap);
  }

  Future<List<QuizQuestion>> getQuestions(String quizId) async {
    final col = await _db
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .orderBy('index')
        .get();
    return col.docs.map((d) => QuizQuestion.fromDoc(d)).toList();
  }

  Future<List<QuizMeta>> getAllQuizzes() async {
    final snap = await _db
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => QuizMeta.fromDoc(d)).toList();
  }

  Future<String> createQuiz(
    QuizMeta meta,
    List<Map<String, dynamic>> questions,
  ) async {
    final quizRef = _db.collection('quizzes').doc();
    await quizRef.set({
      'title': meta.title,
      'description': meta.description,
      'totalQuestions': questions.length,
      'createdBy': meta.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': meta.visibility,
    });
    final batch = _db.batch();
    for (var i = 0; i < questions.length; i++) {
      final qRef = quizRef.collection('questions').doc();
      final q = questions[i];
      batch.set(qRef, {'index': i, ...q});
    }
    await batch.commit();
    return quizRef.id;
  }

  Future<void> deleteQuiz(String quizId) async {
    // Delete all questions first
    final questionsSnap = await _db
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .get();

    final batch = _db.batch();
    for (final doc in questionsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete the quiz document
    batch.delete(_db.collection('quizzes').doc(quizId));

    await batch.commit();
  }
}
