/// Room model based on Firestore schema.
class Room {
  final String id;
  final String code;
  final String hostId;
  final String status; // lobby|playing|ended
  final List<String> playlist; // array of GameType keys
  final int roundIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.playlist,
    required this.roundIndex,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'hostId': hostId,
    'status': status,
    'playlist': playlist,
    'roundIndex': roundIndex,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static Room fromJson(String id, Map<String, dynamic> json) => Room(
    id: id,
    code: json['code'] as String? ?? '',
    hostId: json['hostId'] as String? ?? '',
    status: json['status'] as String? ?? 'lobby',
    playlist: (json['playlist'] as List?)?.cast<String>() ?? const [],
    roundIndex: (json['roundIndex'] as num?)?.toInt() ?? 0,
    createdAt: _ts(json['createdAt']),
    updatedAt: _ts(json['updatedAt']),
  );
}

DateTime? _ts(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    // Firestore Timestamp has toDate()
    final toDate = v.toDate as DateTime Function();
    return toDate();
  } catch (_) {
    return null;
  }
}
