import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

/// Tab tiến độ: tổng quan theo từng bộ thẻ và cài đặt giao diện.
/// Bản giao diện: số liệu chỉ tính trong phiên hiện tại (chưa lưu trữ lâu dài).
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.ofContext(context);
    final accent = p.accent(state.lang);
    final allWords = state.decks.expand((d) => d.words).toList();
    final totalMastered = state.masteredCountOf(allWords);
    final totalDue = state.dueCountOf(allWords);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Tiến độ',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.verified_rounded,
                  value: '$totalMastered',
                  label: 'Đã thành thạo',
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.alarm_rounded,
                  value: '$totalDue',
                  label: 'Cần ôn hôm nay',
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.menu_book_rounded,
                  value: '${allWords.length}',
                  label: 'Tổng số từ',
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theo bộ thẻ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                for (final deck in state.decks)
                  Builder(builder: (context) {
                    final mastered = state.masteredCountOf(deck.words);
                    final total = deck.words.length;
                    final ratio = total == 0 ? 0.0 : mastered / total;
                    final color = p.accent(deck.lang);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  deck.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '$mastered/$total',
                                style: TextStyle(fontSize: 13, color: p.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: p.bg,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Giao diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Panel(
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Tự động')),
                ButtonSegment(value: ThemeMode.light, label: Text('Sáng')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Tối')),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (s) => state.setThemeMode(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return Panel(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, height: 1.25, color: p.muted)),
        ],
      ),
    );
  }
}
