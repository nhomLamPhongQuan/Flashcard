import 'package:flutter/material.dart';

class StudyBackdrop extends StatelessWidget {
  const StudyBackdrop({
    super.key,
    required this.accent,
    required this.child,
  });

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StudyPatternPainter(accent.withAlpha(9)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StudyPatternPainter extends CustomPainter {
  const _StudyPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final center in [
      Offset(size.width * .92, size.height * .12),
      Offset(size.width * .08, size.height * .78),
    ]) {
      canvas.drawCircle(center, 28, paint);
      canvas.drawCircle(center, 38, paint);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * .31 + i * 12;
      canvas.drawLine(
        Offset(size.width * .84, y),
        Offset(size.width * .98, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_StudyPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
