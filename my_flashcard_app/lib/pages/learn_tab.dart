import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/deck_card.dart';
import '../widgets/lang_switcher.dart';

/// Tab chính: chuyển ngôn ngữ và danh sách các bộ thẻ.
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.ofContext(context);
    final decks = state.decksOfLang;
    final words = state.wordsOfLang;
    final totalWords = words.length;
    final totalMastered = state.masteredCountOf(words);
    final totalDue = state.dueCountOf(words);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Học từ vựng',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            totalWords == 0
                ? 'Chưa có từ vựng nào'
                : totalDue > 0
                    ? 'Có $totalDue từ đến hạn ôn · đã thành thạo $totalMastered/$totalWords từ'
                    : 'Đã thành thạo $totalMastered/$totalWords từ trong ngôn ngữ này',
            style: TextStyle(fontSize: 14, color: p.muted),
          ),
          const SizedBox(height: 20),
          const LangSwitcher(),
          const SizedBox(height: 24),
          const Text('Bộ thẻ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final deck in decks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DeckCard(deck: deck),
            ),
        ],
      ),
    );
  }
}
