import 'package:flutter/material.dart';

import '../models/vocab.dart';

/// Bảng màu riêng của ứng dụng. Mỗi ngôn ngữ có một màu nhấn:
/// tiếng Anh là xanh biển, tiếng Nhật là hồng sakura, tiếng Hàn là tím sáng,
/// tiếng Trung là đỏ.
class Palette {
  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.en,
    required this.ja,
    required this.ko,
    required this.zh,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color en;
  final Color ja;
  final Color ko;
  final Color zh;

  Color accent(Lang lang) {
    switch (lang) {
      case Lang.ja:
        return ja;
      case Lang.ko:
        return ko;
      case Lang.zh:
        return zh;
      case Lang.en:
        return en;
    }
  }

  static const light = Palette(
    bg: Color(0xFFF3F5FA),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF172033),
    muted: Color(0xFF667089),
    line: Color(0xFFE3E7F0),
    en: Color(0xFF1B6FC2),
    ja: Color(0xFFE88AAE),
    ko: Color(0xFF9B4DFF),
    zh: Color(0xFFD62828),
  );

  static const dark = Palette(
    bg: Color(0xFF0F131C),
    surface: Color(0xFF182030),
    ink: Color(0xFFEEF1F8),
    muted: Color(0xFF9AA5BD),
    line: Color(0xFF283149),
    en: Color(0xFF6DB3F2),
    ja: Color(0xFFF4A7C2),
    ko: Color(0xFFC28AFF),
    zh: Color(0xFFFF5C5C),
  );

  static Palette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static Palette ofContext(BuildContext context) =>
      of(Theme.of(context).brightness);
}

class AppTheme {
  static const pageTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static ThemeData neutralizeAccents(ThemeData theme, Palette palette) {
    final scheme = theme.colorScheme;
    return theme.copyWith(
      colorScheme: scheme.copyWith(
        primary: palette.muted,
        onPrimary: palette.surface,
        primaryContainer: palette.line,
        onPrimaryContainer: palette.ink,
        secondary: palette.muted,
        onSecondary: palette.surface,
        secondaryContainer: palette.bg,
        onSecondaryContainer: palette.ink,
        tertiary: palette.muted,
        onTertiary: palette.surface,
        tertiaryContainer: palette.bg,
        onTertiaryContainer: palette.ink,
      ),
    );
  }

  static const _cjkFallback = [
    'Noto Sans JP',
    'Noto Sans CJK JP',
    'Hiragino Sans',
    'Yu Gothic',
    'Meiryo',
    'Noto Sans KR',
    'Noto Sans CJK KR',
    'Malgun Gothic',
    'Apple SD Gothic Neo',
  ];

  static ThemeData build(Brightness brightness, Lang lang) {
    final p = Palette.of(brightness);
    final accent = p.accent(lang);
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: isDark ? const Color(0xFF0F131C) : Colors.white,
      surface: p.surface,
      onSurface: p.ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      textTheme: base.textTheme.apply(
        bodyColor: p.ink,
        displayColor: p.ink,
        fontFamilyFallback: _cjkFallback,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: accent.withAlpha(isDark ? 60 : 36),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.ink,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: pageTitleStyle.copyWith(color: p.ink),
      ),
    );
  }
}

/// Làm sáng màu trạng thái một chút ở chế độ tối để đủ tương phản.
Color toneFor(BuildContext context, Color base) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Color.lerp(base, Colors.white, 0.28)! : base;
}
