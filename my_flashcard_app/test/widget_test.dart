import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/firebase_options.dart';
import 'package:my_flashcard_app/main.dart';
import 'package:my_flashcard_app/services/vocab_repository.dart';
import 'package:my_flashcard_app/state/app_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final state = AppState(VocabRepository());
    await state.init();

    await tester.pumpWidget(AppScope(state: state, child: const FlashcardApp()));
    await tester.pump();

    expect(find.text('Thư viện Bộ thẻ'), findsOneWidget);
  });
}
