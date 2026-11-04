import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/vocab.dart';
import '../pages/deck_page.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'panel.dart';

/// Thẻ giới thiệu một bộ từ vựng kèm tiến độ.
class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final accent = p.accent(deck.lang);
    final mastered = AppScope.of(context).masteredCountOf(deck.words);
    final total = deck.words.length;
    final ratio = total == 0 ? 0.0 : mastered / total;

    return Panel(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DeckPage(deck: deck),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withAlpha(12), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 4,
              child: Icon(
                _deckIcon(deck),
                size: 96,
                color: accent.withAlpha(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(28),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accent.withAlpha(35)),
                        ),
                        child: Text(
                          deck.badge,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              deck.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: p.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: accent),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        backgroundColor: p.bg,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        appText(context, '{mastered}/{total} đã thành thạo')
                            .replaceAll('{mastered}', '$mastered')
                            .replaceAll('{total}', '$total'),
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                      const Spacer(),
                      Text(
                        deck.level,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _deckIcon(Deck deck) {
    switch (deck.lang) {
      case Lang.en:
        return Icons.menu_book_rounded;
      case Lang.ja:
        return Icons.auto_stories_rounded;
      case Lang.ko:
        return Icons.translate_rounded;
      case Lang.zh:
        return Icons.translate_rounded;
    }
  }
}
