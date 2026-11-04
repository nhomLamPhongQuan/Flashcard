import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/vocab.dart';
import 'package:my_flashcard_app/services/auth_service.dart';
import 'package:my_flashcard_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<AppState> createInitializedAppState({
  List<Deck> decks = const [],
  FakeFirebaseAuth? firebaseAuth,
  FakeCloudProgressService? cloud,
  FakePublicStatsService? publicStats,
}) async {
  SharedPreferences.setMockInitialValues({});
  final authPlatform = firebaseAuth ?? FakeFirebaseAuth();
  final cloudService = cloud ?? FakeCloudProgressService();
  final publicStatsService = publicStats ?? FakePublicStatsService();
  final displayNames = FakeDisplayNameService();
  final auth = AuthService(
    auth: authPlatform,
    cloudProgress: cloudService,
    displayNames: displayNames,
    publicStats: publicStatsService,
  );
  final state = AppState(
    FakeVocabRepository(decks),
    auth: auth,
    cloud: cloudService,
    publicStats: publicStatsService,
  );
  await state.init();
  return state;
}

const testWord = Word(
  id: 'en_basic_1',
  deckId: 'en_basic',
  lang: Lang.en,
  term: 'apple',
  meaning: 'quả táo',
);

const secondTestWord = Word(
  id: 'en_basic_2',
  deckId: 'en_basic',
  lang: Lang.en,
  term: 'book',
  meaning: 'quyển sách, sách',
);

const testDeck = Deck(
  id: 'en_basic',
  lang: Lang.en,
  title: 'English basics',
  subtitle: 'Common words',
  level: 'A1',
  badge: 'A1',
  words: [testWord, secondTestWord],
);

void ensureTestBinding() {
  TestWidgetsFlutterBinding.ensureInitialized();
}
