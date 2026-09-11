import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class FlashcardItem extends StatefulWidget {
  final Flashcard card;

  const FlashcardItem({super.key, required this.card});

  @override
  State<FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant FlashcardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset thẻ về mặt trước khi chuyển sang từ vựng tiếp theo
    if (oldWidget.card.id != widget.card.id) {
      _controller.reset();
      _isFront = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Hiệu ứng xoay 3D
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildCardSide(
                    title: 'CÂU HỎI / TỪ VỰNG',
                    content: widget.card.question,
                    hint: widget.card.hint,
                    color: Colors.indigo.shade50,
                    textColor: Colors.indigo.shade900,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(
                      title: 'ĐÁP ÁN / NGHĨA',
                      content: widget.card.answer,
                      color: Colors.teal.shade50,
                      textColor: Colors.teal.shade900,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide({
    required String title,
    required String content,
    String? hint,
    required Color color,
    required Color textColor,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: Container(
        width: double.infinity,
        height: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.6)),
            ),
            Column(
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                if (hint != null && hint.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Gợi ý: $hint',
                    style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app,
                    size: 16, color: textColor.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text('Chạm để lật thẻ',
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
