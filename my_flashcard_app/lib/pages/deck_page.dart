import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/page_title_bar.dart';
import '../widgets/slide_page_route.dart';
import '../widgets/word_widgets.dart';
import 'study_page.dart';

/// Chi tiết một bộ thẻ: tiến độ, nút bắt đầu học và danh sách từ.
class DeckPage extends StatelessWidget {
  const DeckPage({super.key, required this.deck});
  final Deck deck;

  void _startStudy(BuildContext context, List<Word> words) {
    Navigator.of(context).push(
      slidePageRoute<void>(
        builder: (_) =>
            StudyPage(title: deck.title, words: words, lang: deck.lang),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.ofContext(context);
    final mastered = state.masteredCountOf(deck.words);
    final due = state.dueWords(deck.words);
    final total = deck.words.length;

    return Scaffold(
      appBar: AppBar(
        title: PageTitleBar(
          title: deck.title,
          icon: Icons.auto_stories_rounded,
          accent: p.accent(deck.lang),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${deck.subtitle}. Cấp độ: ${deck.level}.',
                      style:
                          TextStyle(fontSize: 14, height: 1.4, color: p.muted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _MiniStat(value: due.length, label: 'Đến hạn ôn'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            value: mastered,
                            label: 'Đã thành thạo',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(value: total, label: 'Tổng số từ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: deck.words.isEmpty
                            ? null
                            : () => _startStudy(
                                context, due.isNotEmpty ? due : deck.words),
                        child: Text(
                          due.isNotEmpty
                              ? 'Ôn ${due.length} từ đến hạn'
                              : 'Học lại ${deck.words.length} từ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (due.isEmpty && total > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Không có từ nào đến hạn ôn hôm nay — bạn có thể học lại toàn bộ bộ thẻ để luyện thêm.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: p.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          final shuffled = List<Word>.of(deck.words)..shuffle();
                          _startStudy(context, shuffled);
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 18),
                        label: const Text('Học theo thứ tự ngẫu nhiên'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Danh sách từ (${deck.words.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    final animation = AlwaysStoppedAnimation(value);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.35, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: deck.words.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        WordTile(word: deck.words[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return Panel(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Text('$value',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: p.muted)),
        ],
      ),
    );
  }
}
