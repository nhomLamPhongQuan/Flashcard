import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/main.dart';
import 'package:my_flashcard_app/pages/home_shell.dart';
import 'package:my_flashcard_app/state/app_state.dart';

import 'unit/support/app_state_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('application opens the study shell for a local guest',
      (tester) async {
    final state = await createInitializedAppState();
    await state.startLocalGuest('Test learner');

    await tester.pumpWidget(
      AppScope(state: state, child: const FlashcardApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Học Từ Vựng'), findsOneWidget);
    expect(find.text('Học'), findsOneWidget);
    state.dispose();
  });
}
