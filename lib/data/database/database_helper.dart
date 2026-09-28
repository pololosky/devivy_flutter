import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_pkg;

import '../models/quote.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_pkg.join(dbPath, 'devivy.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE quotes (
            id TEXT PRIMARY KEY,
            clientName TEXT NOT NULL,
            subject TEXT NOT NULL,
            lines TEXT NOT NULL,
            labour REAL NOT NULL DEFAULT 0,
            useSignature INTEGER NOT NULL DEFAULT 0,
            templateId TEXT NOT NULL DEFAULT 'classic',
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            remoteId TEXT
          )
        ''');
      },
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final rows = await db.query('quotes', orderBy: 'updatedAt DESC');
    return rows.map(Quote.fromMap).toList();
  }

  Future<Quote?> getQuoteById(String id) async {
    final db = await database;
    final rows =
        await db.query('quotes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Quote.fromMap(rows.first);
  }

  Future<void> insertQuote(Quote quote) async {
    final db = await database;
    await db.insert('quotes', quote.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQuote(Quote quote) async {
    final db = await database;
    await db.update('quotes', quote.toMap(),
        where: 'id = ?', whereArgs: [quote.id]);
  }

  Future<void> deleteQuote(String id) async {
    final db = await database;
    await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countQuotes() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM quotes');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
