/// Round model per schema under rooms/{roomId}/rounds/{roundId}.
class Round {
  final String id;
  final String gameType; // which mini-game this round uses
  final String state; // intro|play|vote|lock|resolve|results
  final DateTime? timerEnd;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Round({
    required this.id,
    required this.gameType,
    required this.state,
    this.timerEnd,
    this.payload = const {},
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'gameType': gameType,
    'state': state,
    'timerEnd': timerEnd,
    'payload': payload,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static Round fromJson(String id, Map<String, dynamic> json) => Round(
    id: id,
    gameType: json['gameType'] as String? ?? 'unknown',
    state: json['state'] as String? ?? 'intro',
    timerEnd: _ts(json['timerEnd']),
    payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    createdAt: _ts(json['createdAt']),
    updatedAt: _ts(json['updatedAt']),
  );
}

DateTime? _ts(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    final toDate = v.toDate as DateTime Function();
    return toDate();
  } catch (_) {
    return null;
  }
}
