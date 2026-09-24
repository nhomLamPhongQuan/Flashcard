import 'package:flutter/material.dart';

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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DeckPage(deck: deck)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
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
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deck.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 13, color: p.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: p.bg,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$mastered/$total đã thành thạo',
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
              const Spacer(),
              Text(
                deck.level,
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
