import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerAnswer {
  final String id; // composite playerId_qIndex
  final String playerId;
  final int qIndex;
  final dynamic value; // string/number/json
  final DateTime answeredAt;
  final int timeMsFromStart;

  PlayerAnswer({
    required this.id,
    required this.playerId,
    required this.qIndex,
    required this.value,
    required this.answeredAt,
    required this.timeMsFromStart,
  });

  factory PlayerAnswer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PlayerAnswer(
      id: doc.id,
      playerId: (d['playerId'] as String?) ?? '',
      qIndex: (d['qIndex'] as num? ?? 0).toInt(),
      value: d['value'],
      answeredAt:
          (d['answeredAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      timeMsFromStart: (d['timeMsFromStart'] as num? ?? 0).toInt(),
    );
  }
}
