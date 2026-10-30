enum StatsPrivacyMode {
  open,
  restricted,
  cloaked;

  String get label => switch (this) {
        StatsPrivacyMode.open => 'Open',
        StatsPrivacyMode.restricted => 'Restricted',
        StatsPrivacyMode.cloaked => 'Cloaked',
      };

  String get description => switch (this) {
        StatsPrivacyMode.open =>
          'Mọi người có thể xem thống kê, trừ những người trong blacklist.',
        StatsPrivacyMode.restricted =>
          'Chỉ những người trong whitelist có thể xem thống kê.',
        StatsPrivacyMode.cloaked => 'Không ai khác có thể xem thống kê.',
      };

  static StatsPrivacyMode fromValue(String? value) =>
      StatsPrivacyMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => StatsPrivacyMode.cloaked,
      );
}

class StatsPrivacySettings {
  const StatsPrivacySettings({
    this.mode = StatsPrivacyMode.cloaked,
    this.allowedViewerNames = const [],
    this.blockedViewerNames = const [],
  });

  final StatsPrivacyMode mode;
  final List<String> allowedViewerNames;
  final List<String> blockedViewerNames;
}

class PublicDeckStats {
  const PublicDeckStats({
    required this.title,
    required this.language,
    required this.mastered,
    required this.total,
  });

  final String title;
  final String language;
  final int mastered;
  final int total;
}

class PublicStats {
  const PublicStats({
    required this.displayName,
    required this.avatarId,
    required this.masteredCount,
    required this.dueCount,
    required this.totalWords,
    required this.examCount,
    required this.examWordsTotal,
    required this.examCorrectTotal,
    required this.decks,
  });

  final String displayName;
  final String avatarId;
  final int masteredCount;
  final int dueCount;
  final int totalWords;
  final int examCount;
  final int examWordsTotal;
  final int examCorrectTotal;
  final List<PublicDeckStats> decks;

  double get averageExamWords =>
      examCount == 0 ? 0 : examWordsTotal / examCount;

  double get averageExamCorrect =>
      examCount == 0 ? 0 : examCorrectTotal / examCount;

  factory PublicStats.fromJson(Map<String, dynamic> json) {
    final rawDecks = json['decks'];
    final decks = rawDecks is List
        ? rawDecks
            .whereType<Map>()
            .map((deck) => PublicDeckStats(
                  title: deck['title'] as String? ?? '',
                  language: deck['language'] as String? ?? '',
                  mastered: deck['mastered'] as int? ?? 0,
                  total: deck['total'] as int? ?? 0,
                ))
            .toList(growable: false)
        : const <PublicDeckStats>[];

    return PublicStats(
      displayName: json['displayName'] as String? ?? '',
      avatarId: json['avatarId'] as String? ?? 'avatar_01',
      masteredCount: json['masteredCount'] as int? ?? 0,
      dueCount: json['dueCount'] as int? ?? 0,
      totalWords: json['totalWords'] as int? ?? 0,
      examCount: json['examCount'] as int? ?? 0,
      examWordsTotal: json['examWordsTotal'] as int? ?? 0,
      examCorrectTotal: json['examCorrectTotal'] as int? ?? 0,
      decks: decks,
    );
  }
}
