import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/app_language.dart';
import 'package:my_flashcard_app/models/srs.dart';
import 'package:my_flashcard_app/models/vocab.dart';
import 'package:my_flashcard_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_state_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState local guest features', () {
    late AppState state;

    tearDown(() {
      state.dispose();
    });

    test('starts a guest session and persists SRS progress on device',
        () async {
      state = await createInitializedAppState(decks: [testDeck]);
      await state.startLocalGuest('Local learner');
      await state.rate(testWord, SrsRating.easy);

      expect(state.localGuest, isTrue);
      expect(state.currentDisplayName, 'Local learner');
      expect(state.progressOf(testWord).box, 2);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('srs_guest_progress_v1'),
        contains(testWord.id),
      );
    });

    test('restores a saved guest session after signing out', () async {
      state = await createInitializedAppState();
      await state.startLocalGuest('Saved learner');
      await state.rate(testWord, SrsRating.good);
      await state.signOut();

      expect(state.localGuest, isFalse);
      await state.continueLocalGuest();

      expect(state.localGuest, isTrue);
      expect(state.currentDisplayName, 'Saved learner');
      expect(state.progressOf(testWord).box, 1);
    });

    test('saves vocabulary language and application language separately',
        () async {
      state = await createInitializedAppState();
      state.setLang(Lang.ja);
      await state.setAppLanguage(AppLanguage.en);

      final preferences = await SharedPreferences.getInstance();
      expect(state.lang, Lang.ja);
      expect(state.appLanguage, AppLanguage.en);
      expect(preferences.getString('lang_v1'), 'ja');
      expect(preferences.getString('app_language_v1'), 'en');
    });

    test('stores guest avatar locally and rejects unknown avatar IDs',
        () async {
      state = await createInitializedAppState();
      await state.startLocalGuest('Learner');
      await state.selectAvatar('avatar_04');

      final preferences = await SharedPreferences.getInstance();
      expect(state.avatarId, 'avatar_04');
      expect(preferences.getString('local_guest_avatar_v1'), 'avatar_04');
      await expectLater(
        state.selectAvatar('not-an-avatar'),
        throwsArgumentError,
      );
    });

    test('updates and persists a guest display name', () async {
      state = await createInitializedAppState();
      await state.startLocalGuest('Original name');
      await state.updateDisplayName('Updated name');

      final preferences = await SharedPreferences.getInstance();
      expect(state.currentDisplayName, 'Updated name');
      expect(preferences.getString('local_guest_name_v1'), 'Updated name');
    });

    test('validates and stores quiz results for a guest', () async {
      state = await createInitializedAppState();
      await state.startLocalGuest('Learner');
      await state.recordExamResult(wordCount: 5, correctCount: 4);

      expect(state.examCount, 1);
      expect(state.averageExamWords, 5);
      expect(state.averageExamCorrect, 4);
      await expectLater(
        state.recordExamResult(wordCount: 2, correctCount: 3),
        throwsArgumentError,
      );
    });
  });
}
