class UnlockSession {
  UnlockSession({
    required this.id,
    required this.startedAt,
    required this.endsAt,
    required this.unlockedMinutes,
    required this.proofSummary,
    required this.workMinutes,
    required this.qualityScore,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endsAt;
  final int unlockedMinutes;
  final String proofSummary;
  final int workMinutes;
  final int qualityScore;

  bool get isActive => DateTime.now().isBefore(endsAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'unlockedMinutes': unlockedMinutes,
        'proofSummary': proofSummary,
        'workMinutes': workMinutes,
        'qualityScore': qualityScore,
      };

  factory UnlockSession.fromJson(Map<String, dynamic> json) => UnlockSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        unlockedMinutes: json['unlockedMinutes'] as int,
        proofSummary: json['proofSummary'] as String,
        workMinutes: (json['workMinutes'] as int?) ??
            (json['unlockedMinutes'] as int),
        qualityScore: json['qualityScore'] as int? ?? 70,
      );
}
