import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/auth_service.dart';

class AnswerController {
  final _auth = AuthService();
  final _db = FirebaseFirestore.instance;

  Future<void> submitAnswer({
    required String sessionId,
    required int qIndex,
    required dynamic value,
  }) async {
    final uid = _auth.uid!;
    final sessionRef = _db.collection('sessions').doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw Exception('Session missing');
    final sData = sessionSnap.data()!;
    if (sData['questionState'] != 'answering') return; // silently ignore
    final start = (sData['questionStartAt'] as Timestamp?)?.toDate();
    final end = (sData['questionEndAt'] as Timestamp?)?.toDate();
    final now = DateTime.now().toUtc();
    if (end != null && now.isAfter(end)) return; // expired
    final existing = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .doc('${uid}_$qIndex')
        .get();
    if (existing.exists) return; // anti-spam
    final msFromStart = start == null
        ? 0
        : now.difference(start).inMilliseconds;
    await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .doc('${uid}_$qIndex')
        .set({
          'playerId': uid,
          'qIndex': qIndex, // Fixed: was 'questionIndex', should be 'qIndex'
          'value': value,
          'answeredAt': FieldValue.serverTimestamp(),
          'timeMsFromStart': msFromStart,
        });
  }
}
