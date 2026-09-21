import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Khối nền có viền mảnh, dùng cho thẻ bộ từ, ô thống kê, dòng từ vựng...
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: p.line),
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
