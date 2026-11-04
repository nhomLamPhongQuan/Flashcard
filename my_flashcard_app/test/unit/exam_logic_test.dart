import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/exam_logic.dart';
import 'package:my_flashcard_app/models/vocab.dart';

Deck deck(String id, int count) => Deck(
      id: id,
      lang: Lang.en,
      title: id,
      subtitle: '',
      level: '',
      badge: '',
      words: List.generate(
        count,
        (index) => Word(
          id: '${id}_$index',
          deckId: id,
          lang: Lang.en,
          term: 'word $index',
          meaning: 'meaning $index',
        ),
      ),
    );

void main() {
  group('exam question selection', () {
    test('computes per-deck counts and rejects invalid percentages', () {
      final first = deck('first', 10);
      final second = deck('second', 3);

      expect(examWordCount(first, 50), 5);
      expect(examWordCount(second, 50), 1);
      expect(examWordCount(second, 0), 0);
      expect(examWordCount(second, 100), 3);
      expect(() => examWordCount(first, -1), throwsRangeError);
      expect(() => examWordCount(first, 101), throwsRangeError);
    });

    test('selects only requested decks and shuffles a bounded sample', () {
      final first = deck('first', 10);
      final second = deck('second', 4);
      final ignored = deck('ignored', 8);

      final questions = selectExamQuestions(
        decks: [first, second, ignored],
        selectedDeckIds: {'first', 'second'},
        percentage: 50,
        random: Random(4),
      );

      expect(questions, hasLength(7));
      expect(
        questions.where((word) => word.deckId == first.id),
        hasLength(5),
      );
      expect(
        questions.where((word) => word.deckId == second.id),
        hasLength(2),
      );
      expect(questions.every((word) => word.deckId != ignored.id), isTrue);
      expect(questions.map((word) => word.id).toSet(), hasLength(7));
    });

    test('empty deck selection produces no questions', () {
      expect(
        selectExamQuestions(
          decks: [deck('first', 3)],
          selectedDeckIds: const {},
          percentage: 100,
          random: Random(0),
        ),
        isEmpty,
      );
    });
  });

  group('exam answer evaluation', () {
    test('accepts any exact comma-separated meaning ignoring case/spacing', () {
      expect(isExamAnswerCorrect(' QUẢ   TÁO ', 'quả táo, trái táo'), isTrue);
      expect(isExamAnswerCorrect('SÁCH', 'quyển sách, sách'), isTrue);
    });

    test('rejects empty and partial answers', () {
      expect(isExamAnswerCorrect('  ', 'quả táo'), isFalse);
      expect(isExamAnswerCorrect('táo', 'quả táo'), isFalse);
      expect(isExamAnswerCorrect('quả táo!', 'quả táo'), isFalse);
    });
  });
}
