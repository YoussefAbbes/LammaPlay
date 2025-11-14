/// Player model per schema under rooms/{roomId}/players/{playerId}.
class Player {
  final String uid;
  final String nickname;
  final String? avatar;
  final int score;
  final int correctAnswers;
  final int totalAnswers;
  final bool connected;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? kicked;

  Player({
    required this.uid,
    required this.nickname,
    this.avatar,
    this.score = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.connected = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.kicked,
  });

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'avatar': avatar,
    'score': score,
    'correctAnswers': correctAnswers,
    'totalAnswers': totalAnswers,
    'connected': connected,
    'lastSeen': lastSeen,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    if (kicked != null) 'kicked': kicked,
  };

  static Player fromJson(String uid, Map<String, dynamic> json) => Player(
    uid: uid,
    nickname: json['nickname'] as String? ?? 'Player',
    avatar: json['avatar'] as String?,
    score: (json['score'] as num?)?.toInt() ?? 0,
    correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
    totalAnswers: (json['totalAnswers'] as num?)?.toInt() ?? 0,
    connected: json['connected'] as bool? ?? false,
    lastSeen: _ts(json['lastSeen']),
    createdAt: _ts(json['createdAt']),
    updatedAt: _ts(json['updatedAt']),
    kicked: json['kicked'] as bool?,
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
