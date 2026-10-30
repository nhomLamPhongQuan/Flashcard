import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/deck_card.dart';
import '../widgets/lang_switcher.dart';
import '../widgets/page_title_bar.dart';
import '../widgets/slide_page_route.dart';
import '../widgets/study_backdrop.dart';
import 'study_page.dart';

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

    return StudyBackdrop(
      accent: p.accent(state.lang),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PageTitleBar(
                title: 'Học Từ Vựng',
                icon: Icons.style_rounded,
                accent: p.accent(state.lang),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _WelcomeCard(
                    language: state.lang.label,
                    totalDue: totalDue,
                    totalMastered: totalMastered,
                    totalWords: totalWords,
                    accent: p.accent(state.lang),
                    onContinue: () {
                      if (decks.isEmpty) return;
                      final deck = decks.firstWhere(
                        (item) => state.dueWords(item.words).isNotEmpty,
                        orElse: () => decks.firstWhere(
                          (item) => item.words.isNotEmpty,
                          orElse: () => decks.first,
                        ),
                      );
                      final due = state.dueWords(deck.words);
                      final words = due.isNotEmpty ? due : List.of(deck.words)
                        ..shuffle();
                      if (words.isEmpty) return;
                      Navigator.of(context).push(
                        slidePageRoute<void>(
                          builder: (_) => StudyPage(
                            title: deck.title,
                            words: words,
                            lang: deck.lang,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const LangSwitcher(),
                  const SizedBox(height: 24),
                  const Text('Bộ thẻ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final deck in decks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DeckCard(deck: deck),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.language,
    required this.totalDue,
    required this.totalMastered,
    required this.totalWords,
    required this.accent,
    required this.onContinue,
  });

  final String language;
  final int totalDue;
  final int totalMastered;
  final int totalWords;
  final Color accent;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.ofContext(context);
    final progress = totalWords == 0 ? 0.0 : totalMastered / totalWords;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, palette.ink, .22)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              top: -24,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 150,
                color: Colors.white.withAlpha(24),
              ),
            ),
            Positioned(
              right: 24,
              top: 24,
              child: Icon(
                Icons.draw_rounded,
                size: 34,
                color: Colors.white.withAlpha(110),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$language · ${totalDue > 0 ? '$totalDue từ đang chờ ôn' : 'Sẵn sàng học thêm?'}',
                    style: TextStyle(color: Colors.white.withAlpha(220)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withAlpha(60),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$totalMastered/$totalWords',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: totalWords == 0 ? null : onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: accent,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Tiếp tục học'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
