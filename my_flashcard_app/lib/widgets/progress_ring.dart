import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.accent,
    required this.size,
    this.label,
    this.strokeWidth = 9,
  });

  final double value;
  final Color accent;
  final double size;
  final String? label;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        );
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: accent.withAlpha(24),
                color: accent,
              ),
            ),
            if (label != null)
              Text(
                label!,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
          ],
        ),
      ),
    );
  }
}
