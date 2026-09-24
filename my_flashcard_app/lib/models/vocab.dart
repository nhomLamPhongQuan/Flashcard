enum Lang { en, ja, ko }

Lang langFromCode(String? code) {
  switch (code) {
    case 'ja':
      return Lang.ja;
    case 'ko':
      return Lang.ko;
    default:
      return Lang.en;
  }
}

extension LangInfo on Lang {
  String get code {
    switch (this) {
      case Lang.ja:
        return 'ja';
      case Lang.ko:
        return 'ko';
      case Lang.en:
        return 'en';
    }
  }

  String get label {
    switch (this) {
      case Lang.ja:
        return '日本語';
      case Lang.ko:
        return '한국어';
      case Lang.en:
        return 'Tiếng Anh';
    }
  }

  /// true nếu là ngôn ngữ dùng chữ tượng hình/khối (Nhật, Hàn): những ngôn
  /// ngữ này hiển thị cách đọc/phiên âm ở mặt sau thẻ thay vì mặt trước,
  /// khác với tiếng Anh (hiện IPA ngay mặt trước).
  bool get hidesReadingOnFront => this != Lang.en;
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
    this.romanization,
    this.pos,
    this.example,
    this.exampleMeaning,
  });

  final String id;
  final String deckId;
  final Lang lang;

  /// Từ gốc: "meticulous", "学校", "안녕하세요"...
  final String term;

  /// Tiếng Anh: phiên âm IPA. Tiếng Nhật: cách đọc hiragana. Tiếng Hàn:
  /// thường để trống (chữ Hangul đã là cách đọc).
  final String? reading;

  /// Phiên âm La-tinh: romaji (tiếng Nhật) hoặc romanization (tiếng Hàn).
  /// Không dùng cho tiếng Anh.
  final String? romanization;

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
