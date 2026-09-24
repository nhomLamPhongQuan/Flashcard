import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/srs.dart';
import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/flip_card.dart';

/// Màn hình học: lật thẻ rồi tự đánh giá theo hộp Leitner (4 mức:
/// Học lại / Khó / Nhớ / Dễ). Mỗi đánh giá cập nhật hộp + ngày ôn tiếp theo
/// của từ đó và được lưu vĩnh viễn qua AppState.rate().
class StudyPage extends StatefulWidget {
  const StudyPage({
    super.key,
    required this.title,
    required this.words,
    required this.lang,
  });

  final String title;
  final List<Word> words;
  final Lang lang;

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late final int _total = widget.words.length;
  int _index = 0;
  bool _revealed = false;
  int _masteredThisRound = 0;

  Word get _current => widget.words[_index];
  bool get _finished => _index >= widget.words.length;

  void _flip() {
    if (_finished) return;
    setState(() => _revealed = !_revealed);
  }

  void _answer(SrsRating rating) {
    if (!_revealed || _finished) return;
    final state = AppScope.of(context);
    state.rate(_current, rating);
    if (rating == SrsRating.good || rating == SrsRating.easy) {
      if (state.isMastered(_current)) _masteredThisRound++;
    }
    setState(() {
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final accent = p.accent(widget.lang);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.space): _flip,
                const SingleActivator(LogicalKeyboardKey.digit1): () =>
                    _answer(SrsRating.again),
                const SingleActivator(LogicalKeyboardKey.digit2): () =>
                    _answer(SrsRating.hard),
                const SingleActivator(LogicalKeyboardKey.digit3): () =>
                    _answer(SrsRating.good),
                const SingleActivator(LogicalKeyboardKey.digit4): () =>
                    _answer(SrsRating.easy),
              },
              child: Focus(
                autofocus: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    children: [
                      _TopBar(
                        title: widget.title,
                        progress: _total == 0 ? 0 : _index / _total,
                        label: '${_finished ? _total : _index}/$_total',
                        color: accent,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _finished
                            ? _Summary(
                                total: _total,
                                mastered: _masteredThisRound,
                                accent: accent,
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.06, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                  child: FlipCard(
                                    key: ValueKey<int>(_index),
                                    word: _current,
                                    revealed: _revealed,
                                    onTap: _flip,
                                  ),
                                ),
                              ),
                      ),
                      if (!_finished) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 64,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _revealed
                                ? _AnswerRow(
                                    key: const ValueKey('answer'),
                                    onAnswer: _answer)
                                : Padding(
                                    key: const ValueKey('reveal'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: _flip,
                                        child: const Text(
                                          'Hiện đáp án',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.progress,
    required this.label,
    required this.color,
  });

  final String title;
  final double progress;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Thoát',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: p.line,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({super.key, required this.onAnswer});
  final void Function(SrsRating rating) onAnswer;

  @override
  Widget build(BuildContext context) {
    final buttons = <(SrsRating, Color)>[
      (SrsRating.again, toneFor(context, const Color(0xFFD64550))),
      (SrsRating.hard, toneFor(context, const Color(0xFFDB9438))),
      (SrsRating.good, toneFor(context, const Color(0xFF2A9D6A))),
      (SrsRating.easy, toneFor(context, const Color(0xFF2F8FD1))),
    ];
    return Row(
      children: [
        for (final (rating, color) in buttons)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _AnswerButton(
                label: rating.label,
                color: color,
                onTap: () => onAnswer(rating),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton(
      {required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(
      {required this.total, required this.mastered, required this.accent});

  final int total;
  final int mastered;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 72, color: accent),
            const SizedBox(height: 20),
            const Text(
              'Xong lượt học',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              mastered > 0
                  ? 'Bạn đã ôn qua $total từ, trong đó $mastered từ vừa đạt mức thành thạo.'
                  : 'Bạn đã ôn qua $total từ trong bộ thẻ này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: p.muted),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text('Về trang chính'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
