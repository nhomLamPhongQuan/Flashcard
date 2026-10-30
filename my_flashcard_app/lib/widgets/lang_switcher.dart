import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Chuyển nhanh giữa các ngôn ngữ: Anh, Nhật, Hàn, Trung.
class LangSwitcher extends StatelessWidget {
  const LangSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = Palette.ofContext(context).accent(state.lang);
    return SegmentedButton<Lang>(
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.transparent;
        }),
      ),
      segments: const [
        ButtonSegment(value: Lang.en, label: Text('Tiếng Anh')),
        ButtonSegment(value: Lang.ja, label: Text('日本語')),
        ButtonSegment(value: Lang.ko, label: Text('한국어')),
        ButtonSegment(value: Lang.zh, label: Text('中文')),
      ],
      selected: {state.lang},
      onSelectionChanged: (selection) => state.setLang(selection.first),
    );
  }
}
