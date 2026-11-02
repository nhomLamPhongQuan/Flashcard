import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/public_stats.dart';
import 'package:my_flashcard_app/pages/account_dialogs.dart';
import 'package:my_flashcard_app/state/app_state.dart';

import 'support/app_state_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy dialog saves restricted viewer names', (tester) async {
    final state = await createInitializedAppState();
    StatsPrivacyDraft? savedSettings;
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  savedSettings = await showDialog<StatsPrivacyDraft>(
                    context: context,
                    builder: (_) => const StatsPrivacyDialog(
                      settings: StatsPrivacySettings(),
                    ),
                  );
                },
                child: const Text('Open privacy settings'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open privacy settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restricted'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Friend\nStudy buddy');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(savedSettings?.mode, StatsPrivacyMode.restricted);
    expect(savedSettings?.allowedViewerNames, ['Friend', 'Study buddy']);
    state.dispose();
  });

  testWidgets('link dialog validates input and returns account details',
      (tester) async {
    final state = await createInitializedAppState();
    (String, String, String)? submittedDetails;
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  submittedDetails = await showDialog<(String, String, String)>(
                    context: context,
                    builder: (_) => const LinkAccountDialog(),
                  );
                },
                child: const Text('Open link form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open link form'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liên kết'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên của bạn'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Learner');
    await tester.enterText(fields.at(1), 'learner@example.com');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.enterText(fields.at(3), 'secret1');
    await tester.tap(find.text('Liên kết'));
    await tester.pumpAndSettle();

    expect(submittedDetails, ('Learner', 'learner@example.com', 'secret1'));
    state.dispose();
  });
}
