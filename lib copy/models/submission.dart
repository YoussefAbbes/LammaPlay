/// Submission model: per-game shape, stored as arbitrary map.
class Submission {
  final String id;
  final String playerUid;
  final Map<String, dynamic> data;

  Submission({required this.id, required this.playerUid, this.data = const {}});

  Map<String, dynamic> toJson() => {'playerUid': playerUid, ...data};

  static Submission fromJson(String id, Map<String, dynamic> json) =>
      Submission(
        id: id,
        playerUid: json['playerUid'] as String? ?? '',
        data: Map<String, dynamic>.from(json)..remove('playerUid'),
      );
}
