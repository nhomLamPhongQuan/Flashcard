import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flashcard_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE decks (
        id $idType,
        title $textType,
        description TEXT,
        colorCategory TEXT,
        createdAt $textType
      )
    ''');

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

    await db
        .execute('CREATE INDEX idx_flashcards_deckId ON flashcards(deckId)');
    await db.execute(
        'CREATE INDEX idx_flashcards_isLearned ON flashcards(isLearned)');
  }

  // ==================== QUẢN LÝ DECKS ====================

  Future<int> insertDeck(Deck deck) async {
    final db = await instance.database;
    return await db.insert('decks', deck.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Deck>> getAllDecks() async {
    final db = await instance.database;
    final result = await db.query('decks', orderBy: 'createdAt DESC');
    return result.map((json) => Deck.fromMap(json)).toList();
  }

  Future<int> deleteDeck(String deckId) async {
    final db = await instance.database;
    await db.delete('flashcards', where: 'deckId = ?', whereArgs: [deckId]);
    return await db.delete('decks', where: 'id = ?', whereArgs: [deckId]);
  }

  // ==================== QUẢN LÝ FLASHCARDS ====================

  Future<void> insertBatchCards(List<Flashcard> cards) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var card in cards) {
      final map = card.toMap();
      map['isLearned'] = card.isLearned ? 1 : 0;
      batch.insert('flashcards', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Flashcard>> getCardsByDeck({
    required String deckId,
    int limit = 100,
    int offset = 0,
    bool? filterLearned,
  }) async {
    final db = await instance.database;

    String whereClause = 'deckId = ?';
    List<dynamic> whereArgs = [deckId];

    if (filterLearned != null) {
      whereClause += ' AND isLearned = ?';
      whereArgs.add(filterLearned ? 1 : 0);
    }

    final result = await db.query(
      'flashcards',
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'createdAt ASC',
    );

    return result.map((json) {
      final map = Map<String, dynamic>.from(json);
      map['isLearned'] = map['isLearned'] == 1;
      return Flashcard.fromMap(map);
    }).toList();
  }

  Future<int> updateCardLearnedStatus(String cardId, bool isLearned) async {
    final db = await instance.database;
    return await db.update(
      'flashcards',
      {'isLearned': isLearned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<Map<String, int>> getDeckStats(String deckId) async {
    final db = await instance.database;
    final totalResult = await db
        .rawQuery('SELECT COUNT(*) FROM flashcards WHERE deckId = ?', [deckId]);
    final learnedResult = await db.rawQuery(
        'SELECT COUNT(*) FROM flashcards WHERE deckId = ? AND isLearned = 1',
        [deckId]);

    int total = Sqflite.firstIntValue(totalResult) ?? 0;
    int learned = Sqflite.firstIntValue(learnedResult) ?? 0;

    return {'total': total, 'learned': learned};
  }
}
