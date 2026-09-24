import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../theme/app_theme.dart';
import 'word_widgets.dart';

/// Thẻ lật 3D. Mặt trước là từ, mặt sau là nghĩa và ví dụ.
/// Trạng thái lật do widget cha điều khiển qua [revealed].
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.word,
    required this.revealed,
    required this.onTap,
  });

  final Word word;
  final bool revealed;
  final VoidCallback onTap;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.revealed ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed != oldWidget.revealed) {
      if (widget.revealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final angle = _curve.value * math.pi;
            final showFront = angle < math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateY(angle),
              child: showFront
                  ? _Face(front: true, word: widget.word, palette: p)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _Face(front: false, word: widget.word, palette: p),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.front, required this.word, required this.palette});

  final bool front;
  final Word word;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final accent = p.accent(word.lang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: front ? p.line : accent.withAlpha(110),
          width: front ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 48),
              child: Center(
                child: SingleChildScrollView(
                  child: front ? _front(p) : _back(p, accent),
                ),
              ),
            ),
          ),
          if (front && word.pos != null)
            Positioned(top: 18, left: 20, child: PosChip(word.pos!)),
          if (front)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Text(
                  'Chạm để lật thẻ',
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _front(Palette p) {
    final isCjk = word.lang.hidesReadingOnFront;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word.term,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCjk ? 60 : 42,
            fontWeight: isCjk ? FontWeight.w600 : FontWeight.w700,
            height: 1.15,
            letterSpacing: isCjk ? 0 : -0.5,
            color: p.ink,
          ),
        ),
        // Tiếng Anh hiện phiên âm ngay ở mặt trước. Tiếng Nhật/Hàn ẩn cách
        // đọc để người học tự nhớ trước khi lật.
        if (!isCjk && word.reading != null) ...[
          const SizedBox(height: 12),
          Text(
            word.reading!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: p.muted),
          ),
        ],
      ],
    );
  }

  Widget _back(Palette p, Color accent) {
    final isCjk = word.lang.hidesReadingOnFront;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCjk) ...[
          if (word.reading != null)
            Text(
              word.reading!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w600, color: accent),
            ),
          if (word.romanization != null)
            Text(
              word.romanization!,
              style: TextStyle(fontSize: 16, color: p.muted),
            ),
        ] else ...[
          Text(
            word.term,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: p.muted),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          word.meaning,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: p.ink),
        ),
        if (word.example != null) ...[
          const SizedBox(height: 22),
          ExampleBlock(word: word),
        ],
      ],
    );
  }
}
