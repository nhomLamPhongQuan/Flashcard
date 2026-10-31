import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/avatar_catalog.dart';
import '../models/public_stats.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

class PublicStatsLookup extends StatelessWidget {
  const PublicStatsLookup({
    super.key,
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
    final Widget lookupContent;
    if (searchVisible && canLookup) {
      lookupContent = _buildSearchPanel(context);
    } else if (profile != null) {
      lookupContent = _buildProfilePanel(context);
    } else {
      lookupContent = const SizedBox.shrink();
    }

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
            label: Text(appText(context, searchActive ? 'Close' : 'Search')),
          ),
        ),
        if (!canLookup)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              appText(context,
                  'Tính năng này chỉ dành cho tài khoản đã liên kết email.'),
              style: TextStyle(color: palette.muted),
            ),
          ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            reverseDuration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.16),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: lookupContent,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    return Panel(
      key: const ValueKey('public-stats-search'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: !loading,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onLookup(),
            decoration: InputDecoration(
              labelText: appText(context, 'Tên tài khoản'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loading ? null : onLookup,
            icon: const Icon(Icons.search_rounded),
            label: Text(appText(context, loading ? 'Đang tìm...' : 'Search')),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePanel(BuildContext context) {
    final viewedProfile = profile!;
    return Panel(
      key: const ValueKey('public-stats-profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PublicAvatar(avatarId: viewedProfile.avatarId),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewedProfile.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            appText(context, 'Theo bộ thẻ'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final deck in viewedProfile.decks)
            _PublicDeckProgress(deck: deck, palette: palette),
          if (viewedProfile.decks.isEmpty)
            Text(
              appText(context, 'Chưa có tiến độ học để hiển thị.'),
              style: TextStyle(color: palette.muted),
            ),
          const Divider(height: 24),
          _PublicMetric(
            label: appText(context, 'Đã thành thạo'),
            value:
                '${viewedProfile.masteredCount} / ${viewedProfile.totalWords}',
          ),
          _PublicMetric(
            label: appText(context, 'Cần ôn hôm nay'),
            value: '${viewedProfile.dueCount}',
          ),
          _PublicMetric(
            label: appText(context, 'Số bài kiểm tra'),
            value: '${viewedProfile.examCount}',
          ),
          _PublicMetric(
            label: appText(context, 'Từ trung bình / bài'),
            value: viewedProfile.averageExamWords.toStringAsFixed(1),
          ),
          _PublicMetric(
            label: appText(context, 'Đúng trung bình / bài'),
            value: viewedProfile.averageExamCorrect.toStringAsFixed(1),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onSearchAgain,
              icon: const Icon(Icons.search_rounded),
              label: Text(appText(context, 'Search again')),
            ),
          ),
        ],
      ),
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
