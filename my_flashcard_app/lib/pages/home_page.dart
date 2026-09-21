import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/database_helper.dart';
import '../data/mock_data.dart';
import 'study_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Deck> _decks = [];
  Map<String, Map<String, int>> _deckStats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải dữ liệu và ép Seeding nếu CSDL rỗng
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var decks = await DatabaseHelper.instance.getAllDecks();

      // Nếu CSDL rỗng, tự động nạp MockData ngay lập tức
      if (decks.isEmpty) {
        for (var deck in MockData.defaultDecks) {
          await DatabaseHelper.instance.insertDeck(deck);
        }
        await DatabaseHelper.instance.insertBatchCards(MockData.defaultCards);
        decks = await DatabaseHelper.instance.getAllDecks();
      }

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
      setState(() => _errorMessage = e.toString());
      debugPrint('Lỗi HomePage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Ép nạp lại dữ liệu mẫu bằng tay
  Future<void> _forceSeedData() async {
    setState(() => _isLoading = true);
    for (var deck in MockData.defaultDecks) {
      await DatabaseHelper.instance.insertDeck(deck);
    }
    await DatabaseHelper.instance.insertBatchCards(MockData.defaultCards);
    await _loadData();
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
            icon: const Icon(Icons.download),
            tooltip: 'Nạp dữ liệu mẫu',
            onPressed: _forceSeedData,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text('Lỗi: $_errorMessage',
                      style: const TextStyle(color: Colors.red)))
              : _decks.isEmpty
                  ? _buildEmptyState()
                  : _buildDeckList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có bộ thẻ nào trong CSDL',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _forceSeedData,
            icon: const Icon(Icons.file_download),
            label: const Text('Nạp ngay dữ liệu mẫu (IELTS, TOEIC, N3)'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final stat = _deckStats[deck.id] ?? {'total': 0, 'learned': 0};
        final total = stat['total']!;
        final learned = stat['learned']!;
        final progress = total > 0 ? learned / total : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudyPage(deck: deck)),
              );
              _loadData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (deck.description != null) ...[
                    const SizedBox(height: 4),
                    Text(deck.description!,
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 16),
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
                      Text('$learned/$total thẻ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
