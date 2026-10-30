import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/avatar_catalog.dart';
import '../models/public_stats.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/progress_ring.dart';
import '../widgets/study_backdrop.dart';

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
        _lookupError = 'Nhập tên tài khoản để tìm.';
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
        if (result == null) _lookupError = 'Không tìm thấy thống kê công khai.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lookupError =
            error is FirebaseException && error.code == 'permission-denied'
                ? 'Không tìm thấy thống kê hoặc bạn không có quyền xem.'
                : state.auth.friendlyError(error);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Center(
              child: Text(
                'Tiến Độ',
                textAlign: TextAlign.center,
                style: AppTheme.pageTitleStyle,
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                children: [
                  Row(
                    children: [
                      ProgressRing(
                        value: masteryRatio,
                        accent: accent,
                        size: 78,
                        strokeWidth: 7,
                        label: '${(masteryRatio * 100).round()}%',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hành trình học tập',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalMastered trong ${allWords.length} từ đã thành thạo',
                              style: TextStyle(color: p.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.auto_awesome_rounded, color: accent),
                    ],
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả kiểm tra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          icon: Icons.assignment_turned_in_outlined,
                          value: '${state.examCount}',
                          label: 'Số bài kiểm tra',
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          icon: Icons.format_list_numbered_rounded,
                          value: state.averageExamWords.toStringAsFixed(1),
                          label: 'Từ trung bình / bài',
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          icon: Icons.check_circle_outline_rounded,
                          value: state.averageExamCorrect.toStringAsFixed(1),
                          label: 'Đúng trung bình / bài',
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
                                  style:
                                      TextStyle(fontSize: 13, color: p.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratio),
                                duration: const Duration(milliseconds: 700),
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
            _PublicStatsLookup(
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
                final closingSearch = _searchVisible || _viewedStats != null;
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
    );
  }
}

class _PublicStatsLookup extends StatelessWidget {
  const _PublicStatsLookup({
    required this.state,
    required this.controller,
    required this.profile,
    required this.error,
    required this.loading,
    required this.onLookup,
    required this.onSearchAgain,
    required this.searchVisible,
    required this.onToggleSearch,
    required this.palette,
  });

  final AppState state;
  final TextEditingController controller;
  final PublicStats? profile;
  final String? error;
  final bool loading;
  final VoidCallback onLookup;
  final VoidCallback onSearchAgain;
  final bool searchVisible;
  final VoidCallback onToggleSearch;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final canLookup = !state.auth.isAnonymous && !state.unlinkedSession;
    final searchActive = searchVisible || profile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: canLookup && !loading ? onToggleSearch : null,
            icon: Icon(
              searchActive ? Icons.close_rounded : Icons.search_rounded,
            ),
            label: Text(searchActive ? 'Close' : 'Search'),
          ),
        ),
        if (!canLookup)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tính năng này chỉ dành cho tài khoản đã liên kết email.',
              style: TextStyle(color: palette.muted),
            ),
          ),
        if (searchVisible && canLookup) ...[
          const SizedBox(height: 8),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  enabled: !loading,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onLookup(),
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: loading ? null : onLookup,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(loading ? 'Đang tìm...' : 'Search'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ],
        if (profile != null) ...[
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PublicAvatar(avatarId: profile!.avatarId),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile!.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Theo bộ thẻ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final deck in profile!.decks)
                  _PublicDeckProgress(deck: deck, palette: palette),
                if (profile!.decks.isEmpty)
                  Text(
                    'Chưa có tiến độ học để hiển thị.',
                    style: TextStyle(color: palette.muted),
                  ),
                const Divider(height: 24),
                _PublicMetric(
                  label: 'Đã thành thạo',
                  value: '${profile!.masteredCount} / ${profile!.totalWords}',
                ),
                _PublicMetric(
                  label: 'Cần ôn hôm nay',
                  value: '${profile!.dueCount}',
                ),
                _PublicMetric(
                  label: 'Số bài kiểm tra',
                  value: '${profile!.examCount}',
                ),
                _PublicMetric(
                  label: 'Từ trung bình / bài',
                  value: profile!.averageExamWords.toStringAsFixed(1),
                ),
                _PublicMetric(
                  label: 'Đúng trung bình / bài',
                  value: profile!.averageExamCorrect.toStringAsFixed(1),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onSearchAgain,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.avatarId});

  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarOptionById(avatarId);
    final accent = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 28,
      backgroundColor: accent.withAlpha(28),
      child: ClipOval(
        child: Image.asset(
          avatar.assetPath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person_rounded,
            color: accent,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _PublicDeckProgress extends StatelessWidget {
  const _PublicDeckProgress({required this.deck, required this.palette});

  final PublicDeckStats deck;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final ratio =
        deck.total <= 0 ? 0.0 : (deck.mastered / deck.total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${deck.title} · ${deck.language}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${deck.mastered}/${deck.total}',
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: palette.bg,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicMetric extends StatelessWidget {
  const _PublicMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
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
