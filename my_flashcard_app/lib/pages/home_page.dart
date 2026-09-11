import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Deck> _decks = [];
  Map<String, Map<String, int>> _deckStats =
      {}; // Lưu {deckId: {'total': X, 'learned': Y}}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải danh sách bộ thẻ và thống kê tiến độ từ SQLite
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final decks = await DatabaseHelper.instance.getAllDecks();
      final Map<String, Map<String, int>> stats = {};

      for (var deck in decks) {
        final stat = await DatabaseHelper.instance.getDeckStats(deck.id);
        stats[deck.id] = stat;
      }

      setState(() {
        _decks = decks;
        _deckStats = stats;
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hộp thoại tạo mới hoặc chỉnh sửa Deck
  void _showDeckDialog({Deck? deckToEdit}) {
    final titleController =
        TextEditingController(text: deckToEdit?.title ?? '');
    final descController =
        TextEditingController(text: deckToEdit?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deckToEdit == null ? 'Tạo bộ thẻ mới' : 'Sửa bộ thẻ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ thẻ',
                hintText: 'VD: Từ vựng IELTS N3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả ngắn',
                hintText: 'VD: Các từ hay xuất hiện trong đề thi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final deck = Deck(
                id: deckToEdit?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text.trim(),
                description: descController.text.trim(),
                createdAt: deckToEdit?.createdAt,
              );

              await DatabaseHelper.instance.insertDeck(deck);
              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: Text(deckToEdit == null ? 'Tạo mới' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  // Xác nhận xóa bộ thẻ (sẽ xóa sạch cả thẻ con do ON DELETE CASCADE)
  void _confirmDelete(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa "${deck.title}"? Tất cả thẻ bên trong cũng sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteDeck(deck.id);
              if (mounted) Navigator.pop(context);
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện Bộ thẻ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
              ? _buildEmptyState()
              : _buildDeckList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeckDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Bộ thẻ mới'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có bộ thẻ nào',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Bấm nút "Bộ thẻ mới" bên dưới để khởi tạo.'),
        ],
      ),
    );
  }

  Widget _buildDeckList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final stat = _deckStats[deck.id] ?? {'total': 0, 'learned': 0};
        final total = stat['total']!;
        final learned = stat['learned']!;
        final progress = total > 0 ? learned / total : 0.0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        deck.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showDeckDialog(deckToEdit: deck);
                        if (value == 'delete') _confirmDelete(deck);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Chỉnh sửa')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa bộ thẻ',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (deck.description != null &&
                    deck.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    deck.description!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                // Thanh tiến độ học tập
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$learned/$total thẻ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
