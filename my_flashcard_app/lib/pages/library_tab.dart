import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/lang_switcher.dart';
import '../widgets/word_widgets.dart';

/// Tab kho từ: tìm kiếm toàn bộ từ vựng của ngôn ngữ đang chọn.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _query = '';

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
                (w.romaji?.toLowerCase().contains(q) ?? false);
          }).toList();

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kho từ',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${all.length} từ trong ${state.decksOfLang.length} bộ thẻ',
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
                const SizedBox(height: 16),
                const LangSwitcher(),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo từ, cách đọc hoặc nghĩa',
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
                        'Không có từ nào khớp với "$_query".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, height: 1.4, color: p.muted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => WordTile(word: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
