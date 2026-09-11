import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';

class DatabaseHelper {
  // Singleton Pattern: Tạo biến static lưu instance duy nhất của DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database; // Biến giữ kết nối CSDL trong bộ nhớ

  // Constructor ẩn giấu (private) ngăn không cho tạo instance từ bên ngoài
  DatabaseHelper._init();

  // Getter bất đồng bộ để lấy CSDL (nếu chưa mở thì khởi tạo mới)
  Future<Database> get database async {
    if (_database != null) return _database!; // Nếu có kết nối rồi thì trả về
    _database =
        await _initDB('flashcard_app.db'); // Chưa có thì tiến hành khởi tạo
    return _database!;
  }

  // Hàm khởi tạo và kết nối CSDL theo từng nền tảng (Web / Mobile)
  Future<Database> _initDB(String filePath) async {
    // Kiểm tra nếu ứng dụng đang chạy trên trình duyệt Web
    if (kIsWeb) {
      databaseFactory =
          databaseFactoryFfiWeb; // Sử dụng Engine FFI WebAssembly cho Web
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
      );
    }

    // Nếu chạy trên thiết bị Di động (Android/iOS)
    final dbPath =
        await getDatabasesPath(); // Lấy đường dẫn thư mục lưu CSDL mặc định của máy
    final path =
        join(dbPath, filePath); // Nối đường dẫn thư mục với tên file .db

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // Gọi hàm tạo bảng khi Mở database lần đầu tiên
    );
  }

  // Hàm tạo cấu trúc Bảng và Index cho SQLite (chỉ chạy 1 lần duy nhất khi tạo mới DB)
  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY'; // Khóa chính kiểu Text
    const textType = 'TEXT NOT NULL'; // Chuỗi bắt buộc khác Null
    const boolType =
        'INTEGER NOT NULL'; // SQLite không hỗ trợ Bool, lưu Integer (0/1)

    // 1. Tạo Bảng 'decks' (Bộ thẻ)
    await db.execute('''
      CREATE TABLE decks (
        id $idType,
        title $textType,
        description TEXT,
        colorCategory TEXT,
        createdAt $textType
      )
    ''');

    // 2. Tạo Bảng 'flashcards' (Thẻ ghi nhớ)
    await db.execute('''
      CREATE TABLE flashcards (
        id $idType,
        deckId $textType,
        question $textType,
        answer $textType,
        hint TEXT,
        isLearned $boolType,
        createdAt $textType,
        FOREIGN KEY (deckId) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // 3. TẠO INDEX: Giúp tìm kiếm & lọc 10,000+ từ vựng đạt tốc độ tối đa O(log N)
    await db
        .execute('CREATE INDEX idx_flashcards_deckId ON flashcards(deckId)');
    await db.execute(
        'CREATE INDEX idx_flashcards_isLearned ON flashcards(isLearned)');
  }

  // ==================== QUẢN LÝ DECKS (BỘ THẺ) ====================

  // Thêm một Bộ thẻ mới
  Future<int> insertDeck(Deck deck) async {
    final db = await instance.database;
    // conflictAlgorithm.replace: Nếu trùng ID sẽ tự động ghi đè dữ liệu mới
    return await db.insert('decks', deck.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Đọc danh sách tất cả các Bộ thẻ (Sắp xếp mới nhất lên đầu)
  Future<List<Deck>> getAllDecks() async {
    final db = await instance.database;
    final result = await db.query('decks', orderBy: 'createdAt DESC');
    // Map từng dòng dữ liệu SQL (Map) thành đối tượng Deck
    return result.map((json) => Deck.fromMap(json)).toList();
  }

  // Xóa một Bộ thẻ (sẽ tự xóa luôn tất cả thẻ thuộc bộ đó)
  Future<int> deleteDeck(String deckId) async {
    final db = await instance.database;
    // Xóa các Flashcard thuộc về deckId này trước
    await db.delete('flashcards', where: 'deckId = ?', whereArgs: [deckId]);
    // Xóa chính Bộ thẻ
    return await db.delete('decks', where: 'id = ?', whereArgs: [deckId]);
  }

  // ==================== QUẢN LÝ FLASHCARDS (THẺ) ====================

  // Thêm hàng loạt (Batch Insert) - Giúp nạp 10,000+ thẻ vào SQLite cực nhanh dưới 1 giây
  Future<void> insertBatchCards(List<Flashcard> cards) async {
    final db = await instance.database;
    final batch = db
        .batch(); // Gom tất cả lệnh INSERT vào một lượt thực thi (Transaction)

    for (var card in cards) {
      final map = card.toMap();
      map['isLearned'] = card.isLearned ? 1 : 0; // Đổi bool sang 0/1
      batch.insert('flashcards', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true); // Chạy 1 lần duy nhất xuống ổ cứng
  }

  // Lấy danh sách thẻ theo Bộ thẻ có kỹ thuật Phân trang (Pagination / Lazy Loading)
  Future<List<Flashcard>> getCardsByDeck({
    required String deckId,
    int limit = 30, // Số lượng thẻ lấy ra trong 1 trang (mặc định 30)
    int offset = 0, // Vị trí bắt đầu lấy
    bool?
        filterLearned, // Lọc theo trạng thái đã thuộc (true/false) hoặc lấy tất cả (null)
  }) async {
    final db = await instance.database;

    String whereClause = 'deckId = ?';
    List<dynamic> whereArgs = [deckId];

    // Nếu truyền điều kiện lọc thẻ đã thuộc hay chưa
    if (filterLearned != null) {
      whereClause += ' AND isLearned = ?';
      whereArgs.add(filterLearned ? 1 : 0);
    }

    final result = await db.query(
      'flashcards',
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit, // Giới hạn số bản ghi nạp vào RAM
      offset: offset, // Bỏ qua offset bản ghi đầu tiên
      orderBy: 'createdAt ASC',
    );

    return result.map((json) {
      final map = Map<String, dynamic>.from(json);
      map['isLearned'] =
          map['isLearned'] == 1; // Chuyển Integer 0/1 ngược lại thành bool
      return Flashcard.fromMap(map);
    }).toList();
  }

  // Cập nhật trạng thái đã thuộc/chưa thuộc của 1 thẻ
  Future<int> updateCardLearnedStatus(String cardId, bool isLearned) async {
    final db = await instance.database;
    return await db.update(
      'flashcards',
      {'isLearned': isLearned ? 1 : 0}, // Cập nhật duy nhất cột isLearned
      where: 'id = ?', // Tránh dùng nối chuỗi để chống lỗi SQL Injection
      whereArgs: [cardId],
    );
  }

  // Đếm nhanh tổng số thẻ & số thẻ đã thuộc để tính % tiến độ
  Future<Map<String, int>> getDeckStats(String deckId) async {
    final db = await instance.database;
    // Câu lệnh đếm tổng số thẻ trong bộ
    final totalResult = await db
        .rawQuery('SELECT COUNT(*) FROM flashcards WHERE deckId = ?', [deckId]);
    // Câu lệnh đếm số thẻ đã thuộc
    final learnedResult = await db.rawQuery(
        'SELECT COUNT(*) FROM flashcards WHERE deckId = ? AND isLearned = 1',
        [deckId]);

    int total = Sqflite.firstIntValue(totalResult) ?? 0;
    int learned = Sqflite.firstIntValue(learnedResult) ?? 0;

    return {'total': total, 'learned': learned};
  }
}
