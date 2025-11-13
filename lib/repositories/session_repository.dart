import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/models/session.dart';

class SessionRepository {
  final _db = FirebaseFirestore.instance;
  final _rand = Random();

  Future<String> createSession({
    required String quizId,
    required String hostId,
    Map<String, dynamic>? settings,
  }) async {
    final pin = await _generateUniquePin();
    final ref = _db.collection('sessions').doc();

    final sessionData = <String, dynamic>{
      'quizId': quizId,
      'hostId': hostId,
      'pin': pin,
      'status': 'lobby',
      'currentQuestionIndex': -1,
      'questionState': 'intro',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add settings if provided
    if (settings != null) {
      sessionData.addAll(settings);
    }

    await ref.set(sessionData);
    return ref.id;
  }

  Future<String?> resolveSessionByPin(String pin) async {
    final q = await _db
        .collection('sessions')
        .where('pin', isEqualTo: pin)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  Stream<QuizSession?> watchSession(String sessionId) {
    return _db.collection('sessions').doc(sessionId).snapshots().map((s) {
      if (!s.exists) return null;
      return QuizSession.fromDoc(s);
    });
  }

  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('sessions').doc(sessionId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _generateUniquePin() async {
    while (true) {
      final pin = List.generate(6, (_) => _rand.nextInt(10)).join();
      final exists = await resolveSessionByPin(pin);
      if (exists == null) return pin;
    }
  }
}
