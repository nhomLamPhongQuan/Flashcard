import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'panel.dart';

/// Nhãn từ loại (n, v, adj...).
class PosChip extends StatelessWidget {
  const PosChip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.line),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, color: p.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Khối câu ví dụ và bản dịch.
class ExampleBlock extends StatelessWidget {
  const ExampleBlock({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final accent = p.accent(word.lang);
    if (word.example == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word.example!,
            style: TextStyle(fontSize: 17, height: 1.45, color: p.ink),
          ),
          if (word.exampleMeaning != null) ...[
            const SizedBox(height: 6),
            Text(
              word.exampleMeaning!,
              style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Trạng thái học của một từ: Mới / Đã thuộc.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.learned});
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final color = learned ? toneFor(context, const Color(0xFF2A9D6A)) : p.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        learned ? 'Đã thuộc' : 'Mới',
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Một dòng từ vựng trong danh sách. Chạm để xem chi tiết.
class WordTile extends StatelessWidget {
  const WordTile({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final learned = AppScope.of(context).isLearned(word);
    return Panel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => showWordSheet(context, word),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      word.term,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (word.reading != null)
                      Text(
                        word.reading!,
                        style: TextStyle(fontSize: 14, color: p.muted),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  word.meaning,
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusPill(learned: learned),
        ],
      ),
    );
  }
}

void showWordSheet(BuildContext context, Word word) {
  final p = Palette.ofContext(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: p.surface,
    builder: (_) => _WordSheet(word: word),
  );
}

class _WordSheet extends StatelessWidget {
  const _WordSheet({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final accent = p.accent(word.lang);
    final isCjk = word.lang.hidesReadingOnFront;
    final state = AppScope.of(context);
    final learned = state.isLearned(word);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.term,
              style: TextStyle(
                fontSize: isCjk ? 44 : 34,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            if (word.reading != null || word.romanization != null) ...[
              const SizedBox(height: 4),
              Text(
                [word.reading, word.romanization]
                    .whereType<String>()
                    .join('  ·  '),
                style: TextStyle(
                    fontSize: 18, color: accent, fontWeight: FontWeight.w600),
              ),
            ],
            if (word.pos != null) ...[
              const SizedBox(height: 12),
              PosChip(word.pos!),
            ],
            const SizedBox(height: 16),
            Text(
              word.meaning,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const SizedBox(height: 20),
            ExampleBlock(word: word),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => state.markLearned(word, learned: !learned),
                icon:
                    Icon(learned ? Icons.replay_rounded : Icons.check_rounded),
                label: Text(learned ? 'Học lại từ này' : 'Đánh dấu đã thuộc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
