import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/vocab.dart';
import 'package:my_flashcard_app/services/vocab_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads manifest decks and vocabulary assets with unique word IDs',
      () async {
    final decks = await VocabRepository().load();
    final words = decks.expand((deck) => deck.words).toList();

    expect(decks, isNotEmpty);
    expect(words, isNotEmpty);
    expect(decks.map((deck) => deck.id).toSet(), hasLength(decks.length));
    expect(words.map((word) => word.id).toSet(), hasLength(words.length));
    expect(decks.map((deck) => deck.lang).toSet(), contains(Lang.en));
    expect(decks.map((deck) => deck.lang).toSet(), contains(Lang.ja));
    expect(words.every((word) => word.term.isNotEmpty), isTrue);
    expect(words.every((word) => word.meaning.isNotEmpty), isTrue);
    expect(
      words.every(
        (word) => decks.any(
          (deck) =>
              deck.id == word.deckId &&
              deck.lang == word.lang &&
              deck.words.contains(word),
        ),
      ),
      isTrue,
    );
  });
}
