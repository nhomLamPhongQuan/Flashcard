import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/lang_switcher.dart';
import '../widgets/page_title_bar.dart';
import '../widgets/word_widgets.dart';

/// Tab kho từ: tìm kiếm toàn bộ từ vựng của ngôn ngữ đang chọn.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _query = '';
  bool _gridView = false;
  int _listAnimationVersion = 0;

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _listAnimationVersion++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.ofContext(context);
    final accent = p.accent(state.lang);
    final all = state.wordsOfLang;
    final q = _query.trim().toLowerCase();

    final results = q.isEmpty
        ? all
        : all.where((w) {
            return w.term.toLowerCase().contains(q) ||
                w.meaning.toLowerCase().contains(q) ||
                (w.reading?.toLowerCase().contains(q) ?? false) ||
                (w.romanization?.toLowerCase().contains(q) ?? false);
          }).toList();

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: PageTitleBar(
          title: appText(context, 'Kho Từ'),
          icon: Icons.menu_book_rounded,
          accent: accent,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${all.length} ${appText(context, 'từ')} · ${state.decksOfLang.length} ${appText(context, 'bộ thẻ')}',
                          style: TextStyle(fontSize: 14, color: p.muted),
                        ),
                      ),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.view_agenda_outlined),
                            tooltip: appText(context, 'Dạng danh sách'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.grid_view_rounded),
                            tooltip: appText(context, 'Dạng ô'),
                          ),
                        ],
                        selected: {_gridView},
                        onSelectionChanged: (selection) =>
                            setState(() => _gridView = selection.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const LangSwitcher(),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText:
                          appText(context, 'Tìm theo từ, cách đọc hoặc nghĩa'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: p.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: border(p.line),
                      enabledBorder: border(p.line),
                      focusedBorder: border(accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          appText(context,
                                  'Không có từ nào khớp với "{query}".')
                              .replaceAll('{query}', _query),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15, height: 1.4, color: p.muted),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.3, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _gridView
                          ? GridView.builder(
                              key: ValueKey(
                                'word-grid-$_listAnimationVersion',
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 230,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: .9,
                              ),
                              itemCount: results.length,
                              itemBuilder: (_, i) =>
                                  WordBlock(word: results[i]),
                            )
                          : ListView.separated(
                              key: ValueKey(
                                'word-list-$_listAnimationVersion',
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => WordTile(word: results[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
