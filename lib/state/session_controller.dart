import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/repositories/session_repository.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/host_scoring_service.dart';

/// Host-driven session lifecycle logic (Firestore-only authority).
class SessionController {
  final _quizRepo = QuizRepository();
  final _sessionRepo = SessionRepository();
  final _auth = AuthService();
  final _scoringService = HostScoringService();

  Future<String> createSession(
    String quizId, {
    Map<String, dynamic>? settings,
  }) async {
    final uid = _auth.uid!;
    return _sessionRepo.createSession(
      quizId: quizId,
      hostId: uid,
      settings: settings,
    );
  }

  Future<String?> joinByPin(String pin) =>
      _sessionRepo.resolveSessionByPin(pin);

  Future<void> startSession({
    required String sessionId,
    bool hostPlays = false,
  }) async {
    // Loads first question for timing purposes.
    final sessionDoc = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    final snap = await sessionDoc.get();
    if (!snap.exists) throw Exception('Session missing');
    final data = snap.data()!;
    if (data['hostId'] != _auth.uid) throw Exception('Host only');

    // Create player document for host if they want to play
    if (hostPlays) {
      await sessionDoc.collection('players').doc(_auth.uid).set({
        'nickname': 'Host',
        'score': 0,
        'streak': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'isHost': true,
      });
    }

    await sessionDoc.update({
      'status': 'running',
      'currentQuestionIndex': 0,
      'questionState': 'answering',
    });
    await _setTiming(sessionId, quizId: data['quizId'], qIndex: 0);
  }

  Future<void> _setTiming(
    String sessionId, {
    required String quizId,
    required int qIndex,
  }) async {
    final questions = await _quizRepo.getQuestions(quizId);
    if (qIndex < 0 || qIndex >= questions.length) return;
    final q = questions[qIndex];
    final start = DateTime.now().toUtc();
    final end = start.add(Duration(seconds: q.timeLimitSeconds));
    await _sessionRepo.updateSession(sessionId, {
      'questionStartAt': start,
      'questionEndAt': end,
    });
  }

  Future<void> reveal({required String sessionId}) async {
    final sessionDoc = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    final snap = await sessionDoc.get();
    final data = snap.data()!;
    if (data['hostId'] != _auth.uid) throw Exception('Host only');

    final qIndex = (data['currentQuestionIndex'] as num).toInt();

    // Update state to reveal
    await sessionDoc.update({'questionState': 'reveal'});

    // Execute scoring calculation
    await _scoringService.scoreQuestion(sessionId: sessionId, qIndex: qIndex);
  }

  Future<void> nextQuestion({required String sessionId}) async {
    final sessionDoc = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    final snap = await sessionDoc.get();
    final data = snap.data()!;
    if (data['hostId'] != _auth.uid) throw Exception('Host only');
    final quizId = data['quizId'] as String;
    final current = (data['currentQuestionIndex'] as num).toInt();
    final questions = await _quizRepo.getQuestions(quizId);
    if (current + 1 >= questions.length) {
      // End session -> podium
      await sessionDoc.update({'status': 'ended', 'questionState': 'ended'});
      return;
    }
    final next = current + 1;
    await sessionDoc.update({
      'currentQuestionIndex': next,
      'questionState': 'answering',
    });
    await _setTiming(sessionId, quizId: quizId, qIndex: next);
  }
}
