class WorkSession {
  WorkSession({
    required this.startedAt,
    this.goalMinutes = 30,
  });

  final DateTime startedAt;
  final int goalMinutes;

  int get elapsedMinutes {
    final elapsed = DateTime.now().difference(startedAt).inMinutes;
    return elapsed < 1 ? 1 : elapsed;
  }

  int get elapsedSeconds {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'goalMinutes': goalMinutes,
      };

  factory WorkSession.fromJson(Map<String, dynamic> json) => WorkSession(
        startedAt: DateTime.parse(json['startedAt'] as String),
        goalMinutes: json['goalMinutes'] as int? ?? 30,
      );
}
