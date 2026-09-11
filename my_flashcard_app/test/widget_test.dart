import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Khởi chạy FlashcardApp thay vì MyApp cũ
    await tester.pumpWidget(const FlashcardApp());

    // Kiểm tra AppBar hiển thị đúng tiêu đề
    expect(find.text('Thư viện Bộ thẻ'), findsOneWidget);
  });
}
