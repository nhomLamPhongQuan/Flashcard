enum Lang { en, ja }

Lang langFromCode(String? code) => code == 'ja' ? Lang.ja : Lang.en;

extension LangInfo on Lang {
  String get code => this == Lang.ja ? 'ja' : 'en';
  String get label => this == Lang.ja ? '日本語' : 'Tiếng Anh';
}

/// Một từ vựng trong kho từ.
class Word {
  const Word({
    required this.id,
    required this.deckId,
    required this.lang,
    required this.term,
    required this.meaning,
    this.reading,
    this.romaji,
    this.pos,
    this.example,
    this.exampleMeaning,
  });

  final String id;
  final String deckId;
  final Lang lang;

  /// Từ gốc: "meticulous", "学校"...
  final String term;

  /// Tiếng Anh: phiên âm IPA. Tiếng Nhật: cách đọc hiragana.
  final String? reading;

  /// Chỉ dùng cho tiếng Nhật.
  final String? romaji;

  /// Từ loại: n, v, adj, adj-i...
  final String? pos;
  final String meaning;
  final String? example;
  final String? exampleMeaning;
}

/// Một bộ thẻ (nhóm từ vựng theo chủ đề hoặc cấp độ).
class Deck {
  const Deck({
    required this.id,
    required this.lang,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.badge,
    required this.words,
  });

  final String id;
  final Lang lang;
  final String title;
  final String subtitle;
  final String level;
  final String badge;
  final List<Word> words;
}
