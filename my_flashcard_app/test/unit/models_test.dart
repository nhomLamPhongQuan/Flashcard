import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/app_language.dart';
import 'package:my_flashcard_app/models/avatar_catalog.dart';
import 'package:my_flashcard_app/models/public_stats.dart';
import 'package:my_flashcard_app/models/srs.dart';
import 'package:my_flashcard_app/models/vocab.dart';

void main() {
  group('WordProgress and Leitner SRS', () {
    test('new words are immediately due and not mastered', () {
      final progress = WordProgress.initial();

      expect(progress.box, 0);
      expect(progress.isDue(DateTime.now()), isTrue);
      expect(progress.isMastered, isFalse);
    });

    test('all ratings update the box and interval as specified', () {
      final now = DateTime(2026, 11, 2);
      final progress = WordProgress(box: 2, nextReview: now);
      final cases = {
        SrsRating.again: (0, 0),
        SrsRating.hard: (1, 1),
        SrsRating.good: (3, 7),
        SrsRating.easy: (4, 14),
      };

      for (final entry in cases.entries) {
        final rated = progress.rated(entry.key, now);
        expect(rated.box, entry.value.$1);
        expect(rated.nextReview, now.add(Duration(days: entry.value.$2)));
      }
    });

    test('ratings respect minimum and maximum boxes', () {
      final now = DateTime(2026, 11, 2);

      expect(
        WordProgress(box: 0, nextReview: now).nextBoxFor(SrsRating.hard),
        0,
      );
      expect(
        WordProgress(box: kMaxBox, nextReview: now).nextBoxFor(SrsRating.good),
        kMaxBox,
      );
      expect(
        WordProgress(box: kMaxBox, nextReview: now).nextBoxFor(SrsRating.easy),
        kMaxBox,
      );
    });

    test('mastery and due checks use their documented boundaries', () {
      final now = DateTime(2026, 11, 2);
      expect(
        WordProgress(box: kMasteredBox, nextReview: now).isMastered,
        isTrue,
      );
      expect(
        WordProgress(box: kMasteredBox - 1, nextReview: now).isMastered,
        isFalse,
      );
      expect(
        WordProgress(box: 1, nextReview: now).isDue(now),
        isTrue,
      );
      expect(
        WordProgress(box: 1, nextReview: now.add(const Duration(seconds: 1)))
            .isDue(now),
        isFalse,
      );
    });

    test('progress round-trips through JSON', () {
      final progress = WordProgress(
        box: 4,
        nextReview: DateTime(2026, 11, 16),
      );

      expect(WordProgress.fromJson(progress.toJson()).box, progress.box);
      expect(
        WordProgress.fromJson(progress.toJson()).nextReview,
        progress.nextReview,
      );
    });
  });

  group('language and profile models', () {
    test('vocabulary and app languages parse supported and unknown codes', () {
      expect(langFromCode('ja'), Lang.ja);
      expect(langFromCode('ko'), Lang.ko);
      expect(langFromCode('zh'), Lang.zh);
      expect(langFromCode('unsupported'), Lang.en);
      expect(appLanguageFromCode('en'), AppLanguage.en);
      expect(appLanguageFromCode('unsupported'), AppLanguage.vi);
      expect(Lang.zh.hidesReadingOnFront, isTrue);
      expect(Lang.en.hidesReadingOnFront, isFalse);
    });

    test('avatar lookup falls back safely for unknown identifiers', () {
      expect(avatarOptions, hasLength(8));
      expect(avatarOptionById('avatar_03').id, 'avatar_03');
      expect(avatarOptionById('unknown').id, 'avatar_01');
      expect(avatarOptionById(null).id, 'avatar_01');
    });

    test('privacy mode defaults to cloaked for unknown values', () {
      expect(StatsPrivacyMode.fromValue('open'), StatsPrivacyMode.open);
      expect(
        StatsPrivacyMode.fromValue('restricted'),
        StatsPrivacyMode.restricted,
      );
      expect(
        StatsPrivacyMode.fromValue('unexpected'),
        StatsPrivacyMode.cloaked,
      );
      expect(const StatsPrivacySettings().mode, StatsPrivacyMode.cloaked);
    });

    test('public progress parses complete and incomplete documents', () {
      final stats = PublicStats.fromJson({
        'displayName': 'Learner',
        'avatarId': 'avatar_02',
        'masteredCount': 3,
        'dueCount': 4,
        'totalWords': 10,
        'examCount': 2,
        'examWordsTotal': 20,
        'examCorrectTotal': 16,
        'decks': [
          {
            'title': 'Basics',
            'language': 'English',
            'mastered': 3,
            'total': 10,
          },
        ],
      });

      expect(stats.displayName, 'Learner');
      expect(stats.decks.single.mastered, 3);
      expect(stats.averageExamWords, 10);
      expect(stats.averageExamCorrect, 8);

      final empty = PublicStats.fromJson({});
      expect(empty.displayName, isEmpty);
      expect(empty.avatarId, 'avatar_01');
      expect(empty.decks, isEmpty);
      expect(empty.averageExamWords, 0);
      expect(PublicStats.fromJson({'decks': 'invalid'}).decks, isEmpty);
    });
  });
}
