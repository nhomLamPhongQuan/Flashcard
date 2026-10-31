import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/public_stats.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/page_title_bar.dart';
import '../widgets/progress_ring.dart';
import '../widgets/study_backdrop.dart';
import 'public_stats_lookup.dart';

/// Tab tiến độ: kết quả kiểm tra đã lưu và tổng quan học tập theo bộ thẻ.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final TextEditingController _nameController = TextEditingController();
  PublicStats? _viewedStats;
  String? _lookupError;
  bool _lookingUp = false;
  bool _searchVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _lookupStats(AppState state) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _viewedStats = null;
        _lookupError = appText(context, 'Nhập tên tài khoản để tìm.');
      });
      return;
    }

    setState(() {
      _lookingUp = true;
      _lookupError = null;
      _viewedStats = null;
    });
    try {
      final result = await state.lookupPublicStats(name);
      if (!mounted) return;
      setState(() {
        _viewedStats = result;
        if (result != null) _searchVisible = false;
        if (result == null) {
          _lookupError = appText(context, 'Không tìm thấy thống kê công khai.');
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lookupError = error is FirebaseException &&
                error.code == 'permission-denied'
            ? appText(
                context, 'Không tìm thấy thống kê hoặc bạn không có quyền xem.')
            : appText(context, state.auth.friendlyError(error));
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.ofContext(context);
    final accent = p.accent(state.lang);
    final allWords = state.decks.expand((d) => d.words).toList();
    final totalMastered = state.masteredCountOf(allWords);
    final totalDue = state.dueCountOf(allWords);

    final masteryRatio =
        allWords.isEmpty ? 0.0 : totalMastered / allWords.length;
    return StudyBackdrop(
      accent: accent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PageTitleBar(
                title: appText(context, 'Tiến Độ'),
                icon: Icons.insights_rounded,
                accent: accent,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, Color.lerp(accent, p.ink, .22)!],
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
                              Icons.insights_rounded,
                              size: 150,
                              color: Colors.white.withAlpha(24),
                            ),
                          ),
                          Positioned(
                            right: 24,
                            top: 24,
                            child: Icon(
                              Icons.celebration_rounded,
                              size: 34,
                              color: Colors.white.withAlpha(110),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ProgressRing(
                                      value: masteryRatio,
                                      accent: Colors.white,
                                      size: 78,
                                      strokeWidth: 7,
                                      label: '${(masteryRatio * 100).round()}%',
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appText(
                                                context, 'Hành trình học tập'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            appText(context,
                                                    '{mastered} trong {total} từ đã thành thạo')
                                                .replaceAll('{mastered}',
                                                    '$totalMastered')
                                                .replaceAll('{total}',
                                                    '${allWords.length}'),
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withAlpha(220),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.auto_awesome_rounded,
                                        color: Colors.white),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Metric(
                                        icon: Icons.verified_rounded,
                                        value: '$totalMastered',
                                        label:
                                            appText(context, 'Đã thành thạo'),
                                        color: Colors.white,
                                        onAccent: true,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Metric(
                                        icon: Icons.alarm_rounded,
                                        value: '$totalDue',
                                        label:
                                            appText(context, 'Cần ôn hôm nay'),
                                        color: Colors.white,
                                        onAccent: true,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Metric(
                                        icon: Icons.menu_book_rounded,
                                        value: '${allWords.length}',
                                        label: appText(context, 'Tổng số từ'),
                                        color: Colors.white,
                                        onAccent: true,
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
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appText(context, 'Kết quả kiểm tra'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.assignment_turned_in_outlined,
                                value: '${state.examCount}',
                                label: appText(context, 'Số bài kiểm tra'),
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Metric(
                                icon: Icons.format_list_numbered_rounded,
                                value:
                                    state.averageExamWords.toStringAsFixed(1),
                                label: appText(context, 'Từ trung bình / bài'),
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Metric(
                                icon: Icons.check_circle_outline_rounded,
                                value:
                                    state.averageExamCorrect.toStringAsFixed(1),
                                label:
                                    appText(context, 'Đúng trung bình / bài'),
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appText(context, 'Theo bộ thẻ'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
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
                                        style: TextStyle(
                                            fontSize: 13, color: p.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: ratio),
                                      duration:
                                          const Duration(milliseconds: 700),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, _) =>
                                          LinearProgressIndicator(
                                        value: value,
                                        minHeight: 7,
                                        backgroundColor: p.bg,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PublicStatsLookup(
                    state: state,
                    controller: _nameController,
                    profile: _viewedStats,
                    error: _lookupError,
                    loading: _lookingUp,
                    onLookup: () => _lookupStats(state),
                    onSearchAgain: () => setState(() {
                      _viewedStats = null;
                      _lookupError = null;
                      _nameController.clear();
                      _searchVisible = true;
                    }),
                    searchVisible: _searchVisible,
                    onToggleSearch: () {
                      final closingSearch =
                          _searchVisible || _viewedStats != null;
                      setState(() {
                        _searchVisible = !closingSearch;
                        _lookupError = null;
                        if (closingSearch) {
                          _viewedStats = null;
                          _nameController.clear();
                        }
                      });
                    },
                    palette: p,
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onAccent = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final tileColor = onAccent
        ? Color.lerp(
            p.accent(AppScope.of(context).lang),
            p.surface,
            0.78,
          )!
        : null;
    return Panel(
      radius: 16,
      padding: const EdgeInsets.all(14),
      color: tileColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color: onAccent ? p.accent(AppScope.of(context).lang) : color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              color: onAccent ? p.ink : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}
