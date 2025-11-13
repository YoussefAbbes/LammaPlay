/// Vote model: per-game shape, stored as arbitrary map.
class Vote {
  final String id;
  final String voterUid;
  final Map<String, dynamic> data;

  Vote({required this.id, required this.voterUid, this.data = const {}});

  Map<String, dynamic> toJson() => {'voterUid': voterUid, ...data};

  static Vote fromJson(String id, Map<String, dynamic> json) => Vote(
    id: id,
    voterUid: json['voterUid'] as String? ?? '',
    data: Map<String, dynamic>.from(json)..remove('voterUid'),
  );
}
