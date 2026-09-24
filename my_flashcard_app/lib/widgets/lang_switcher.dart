import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';

/// Chuyển nhanh giữa các ngôn ngữ: Anh, Nhật, Hàn.
class LangSwitcher extends StatelessWidget {
  const LangSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SegmentedButton<Lang>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: Lang.en, label: Text('Tiếng Anh')),
        ButtonSegment(value: Lang.ja, label: Text('日本語')),
        ButtonSegment(value: Lang.ko, label: Text('한국어')),
      ],
      selected: {state.lang},
      onSelectionChanged: (selection) => state.setLang(selection.first),
    );
  }
}
