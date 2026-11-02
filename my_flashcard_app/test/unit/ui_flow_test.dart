import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/models/vocab.dart';
import 'package:my_flashcard_app/pages/exam_page.dart';
import 'package:my_flashcard_app/pages/study_page.dart';
import 'package:my_flashcard_app/state/app_state.dart';

import 'support/app_state_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('study and quiz screens', () {
    testWidgets('reveals a flashcard and saves the selected rating',
        (tester) async {
      final state = await createInitializedAppState(decks: [testDeck]);
      await state.startLocalGuest('Learner');
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            home: StudyPage(
              title: testDeck.title,
              words: const [testWord],
              lang: Lang.en,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('apple'), findsOneWidget);
      await tester.tap(find.text('Hiện đáp án'));
      await tester.pumpAndSettle();
      expect(find.text('quả táo'), findsOneWidget);

      await tester.tap(find.text('Dễ'));
      await tester.pumpAndSettle();

      expect(state.progressOf(testWord).box, 2);
      expect(find.text('Xong lượt học'), findsOneWidget);
      state.dispose();
    });

    testWidgets('selects a deck, grades an answer, and shows quiz results',
        (tester) async {
      final state = await createInitializedAppState(decks: [testDeck]);
      await state.startLocalGuest('Learner');
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: const MaterialApp(home: Scaffold(body: ExamPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bài Kiểm Tra'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu kiểm tra · 1 từ'));
      await tester.pumpAndSettle();

      final prompt = (tester.widgetList<Text>(find.byType(Text)))
          .map((text) => text.data)
          .whereType<String>()
          .firstWhere((text) => text == 'apple' || text == 'book');
      final correctAnswer = prompt == 'apple' ? 'quả táo' : 'quyển sách';
      await tester.enterText(find.byType(TextField).first, correctAnswer);
      await tester.tap(find.text('Kiểm tra đáp án'));
      await tester.pumpAndSettle();

      expect(find.text('Chính xác!'), findsOneWidget);
      await tester.tap(find.text('Xem kết quả'));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn Thành Bài Kiểm Tra'), findsOneWidget);
      expect(find.text('Trả lời đúng'), findsOneWidget);
      expect(state.examCount, 1);
      state.dispose();
    });
  });
}
