import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/database_helper.dart';
import '../widgets/flashcard_item.dart';

class StudyPage extends StatefulWidget {
  final Deck deck;

  const StudyPage({super.key, required this.deck});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // Tải danh sách thẻ từ SQLite theo deckId
  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await DatabaseHelper.instance.getCardsByDeck(
      deckId: widget.deck.id,
      limit: 100, // Tải trước 100 thẻ để học
    );
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  // Đánh dấu thuộc / chưa thuộc và lưu xuống SQLite
  Future<void> _markLearnedStatus(bool isLearned) async {
    if (_cards.isEmpty) return;

    final currentCard = _cards[_currentIndex];
    await DatabaseHelper.instance
        .updateCardLearnedStatus(currentCard.id, isLearned);

    setState(() {
      currentCard.isLearned = isLearned;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      } else {
        _showCompletedDialog();
      }
    });
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Hoàn thành!'),
        content: const Text('Bạn đã duyệt hết toàn bộ thẻ trong lượt học này.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context,
                  true); // Trả về true để HomePage làm mới lại progress
            },
            child: const Text('Về Thư viện'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Tiến độ hiển thị số thẻ
                      Text(
                        'Thẻ ${_currentIndex + 1} / ${_cards.length}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Card Lật 3D
                      Expanded(
                        child: FlashcardItem(card: _cards[_currentIndex]),
                      ),
                      const SizedBox(height: 20),
                      // Các nút bấm đánh dấu trạng thái
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _markLearnedStatus(false),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              label: const Text('Cần học lại',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _markLearnedStatus(true),
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text('Đã thuộc',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Bộ thẻ này chưa có từ vựng nào!'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}
