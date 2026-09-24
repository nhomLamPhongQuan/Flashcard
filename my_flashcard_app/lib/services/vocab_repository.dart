import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/vocab.dart';

/// Đọc kho từ vựng từ assets/vocab/.
///
/// Cấu trúc (từ khi kho từ được mở rộng lên nhiều chủ đề):
///   assets/vocab/manifest.json        -> danh sách bộ thẻ (metadata, KHÔNG có từ)
///   assets/vocab/decks/<deckId>.json  -> nội dung từ vựng của từng bộ thẻ
///
/// Tách metadata (manifest) ra khỏi nội dung (decks/*.json) giúp:
///   - Mỗi bộ thẻ là 1 file riêng, dễ thêm/sửa/xoá mà không đụng file khác.
///   - Có thể mở rộng sang tải "lười" (lazy load) từng bộ khi cần, thay vì
///     phải đọc toàn bộ hàng nghìn từ ngay lúc khởi động app.
class VocabRepository {
  static const _manifestPath = 'assets/vocab/manifest.json';
  static const _decksDir = 'assets/vocab';

  Future<List<Deck>> load() async {
    final manifestRaw = await rootBundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final deckMetas = manifest['decks'] as List<dynamic>;

    final decks = <Deck>[];
    for (final item in deckMetas) {
      final meta = item as Map<String, dynamic>;
      final deckId = meta['id'] as String;
      final lang = langFromCode(meta['lang'] as String?);
      final file = meta['file'] as String;

      final wordsRaw = await rootBundle.loadString('$_decksDir/$file');
      final wordsData = jsonDecode(wordsRaw) as Map<String, dynamic>;
      final rawWords = wordsData['words'] as List<dynamic>;

      final words = <Word>[];
      for (var i = 0; i < rawWords.length; i++) {
        final w = rawWords[i] as Map<String, dynamic>;
        words.add(Word(
          id: '${deckId}_${i + 1}',
          deckId: deckId,
          lang: lang,
          term: w['t'] as String,
          reading: w['r'] as String?,
          romanization: w['ro'] as String?,
          pos: w['p'] as String?,
          meaning: w['m'] as String,
          example: w['e'] as String?,
          exampleMeaning: w['v'] as String?,
        ));
      }

      decks.add(Deck(
        id: deckId,
        lang: lang,
        title: meta['title'] as String,
        subtitle: (meta['subtitle'] as String?) ?? '',
        level: (meta['level'] as String?) ?? '',
        badge: (meta['badge'] as String?) ?? '',
        words: words,
      ));
    }
    return decks;
  }
}
