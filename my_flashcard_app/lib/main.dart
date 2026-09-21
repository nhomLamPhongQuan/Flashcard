import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'services/vocab_repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState(VocabRepository());
  await state.init();

  runApp(AppScope(state: state, child: const FlashcardApp()));
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppScope.of đăng ký widget này là dependent của AppState, nên mỗi lần
    // notifyListeners() được gọi, FlashcardApp sẽ tự rebuild với theme mới.
    final state = AppScope.of(context);
    return MaterialApp(
      title: 'Từ vựng Anh - Nhật',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.build(Brightness.light, state.lang),
      darkTheme: AppTheme.build(Brightness.dark, state.lang),
      home: const HomeShell(),
    );
  }
}
