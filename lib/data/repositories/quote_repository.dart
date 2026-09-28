import '../database/database_helper.dart';
import '../models/quote.dart';

class QuoteRepository {
  QuoteRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Quote>> getAll() => _db.getAllQuotes();

  Future<Quote?> getById(String id) => _db.getQuoteById(id);

  Future<void> save(Quote quote) async {
    final existing = await _db.getQuoteById(quote.id);
    if (existing == null) {
      await _db.insertQuote(quote);
    } else {
      await _db.updateQuote(quote);
    }
  }

  Future<void> delete(String id) => _db.deleteQuote(id);

  Future<int> count() => _db.countQuotes();
}
