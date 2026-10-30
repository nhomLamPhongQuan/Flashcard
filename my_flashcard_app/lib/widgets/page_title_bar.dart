import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageTitleBar extends StatelessWidget {
  const PageTitleBar({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.ofContext(context);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.line),
          bottom: BorderSide(color: palette.line),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    right: 0,
                    top: -18,
                    child: Icon(
                      icon,
                      size: 60,
                      color: accent.withAlpha(14),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
