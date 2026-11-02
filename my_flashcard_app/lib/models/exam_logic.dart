import 'dart:math';

import 'vocab.dart';

int examWordCount(Deck deck, int percentage) {
  if (percentage < 0 || percentage > 100) {
    throw RangeError.range(percentage, 0, 100, 'percentage');
  }
  return deck.words.length * percentage ~/ 100;
}

List<Word> selectExamQuestions({
  required Iterable<Deck> decks,
  required Set<String> selectedDeckIds,
  required int percentage,
  Random? random,
}) {
  final rng = random ?? Random();
  final questions = <Word>[];
  for (final deck in decks) {
    if (!selectedDeckIds.contains(deck.id)) continue;
    final words = List<Word>.of(deck.words)..shuffle(rng);
    questions.addAll(words.take(examWordCount(deck, percentage)));
  }
  questions.shuffle(rng);
  return questions;
}

bool isExamAnswerCorrect(String answer, String acceptedMeanings) {
  final normalizedAnswer = answer.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  if (normalizedAnswer.isEmpty) return false;
  return acceptedMeanings
      .split(',')
      .map((meaning) => meaning.replaceAll(RegExp(r'\s+'), '').toLowerCase())
      .where((meaning) => meaning.isNotEmpty)
      .contains(normalizedAnswer);
}
