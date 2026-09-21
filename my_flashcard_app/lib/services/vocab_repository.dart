import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/vocab.dart';

/// Đọc kho từ vựng có sẵn từ assets/vocab/vocabulary.json.
class VocabRepository {
  static const _assetPath = 'assets/vocab/vocabulary.json';

  Future<List<Deck>> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final decks = <Deck>[];

    for (final item in data['decks'] as List<dynamic>) {
      final d = item as Map<String, dynamic>;
      final deckId = d['id'] as String;
      final lang = langFromCode(d['lang'] as String?);
      final rawWords = d['words'] as List<dynamic>;
      final words = <Word>[];

      for (var i = 0; i < rawWords.length; i++) {
        final w = rawWords[i] as Map<String, dynamic>;
        words.add(Word(
          id: '${deckId}_${i + 1}',
          deckId: deckId,
          lang: lang,
          term: w['t'] as String,
          reading: w['r'] as String?,
          romaji: w['ro'] as String?,
          pos: w['p'] as String?,
          meaning: w['m'] as String,
          example: w['e'] as String?,
          exampleMeaning: w['v'] as String?,
        ));
      }

      decks.add(Deck(
        id: deckId,
        lang: lang,
        title: d['title'] as String,
        subtitle: (d['subtitle'] as String?) ?? '',
        level: (d['level'] as String?) ?? '',
        badge: (d['badge'] as String?) ?? '',
        words: words,
      ));
    }
    return decks;
  }
}
