class UnlockSession {
  UnlockSession({
    required this.id,
    required this.startedAt,
    required this.endsAt,
    required this.unlockedMinutes,
    required this.proofSummary,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endsAt;
  final int unlockedMinutes;
  final String proofSummary;

  bool get isActive => DateTime.now().isBefore(endsAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'unlockedMinutes': unlockedMinutes,
        'proofSummary': proofSummary,
      };

  factory UnlockSession.fromJson(Map<String, dynamic> json) => UnlockSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        unlockedMinutes: json['unlockedMinutes'] as int,
        proofSummary: json['proofSummary'] as String,
      );
}
