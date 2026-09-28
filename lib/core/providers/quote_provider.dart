import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import '../../data/repositories/quote_repository.dart';

// Free plan quota
const int kFreeQuotaLimit = 5;

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(DatabaseHelper.instance);
});

final quotesProvider =
    AsyncNotifierProvider<QuotesNotifier, List<Quote>>(QuotesNotifier.new);

class QuotesNotifier extends AsyncNotifier<List<Quote>> {
  @override
  Future<List<Quote>> build() async {
    return ref.read(quoteRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(quoteRepositoryProvider).getAll());
  }

  /// Returns the newly-created quote id, or null if quota exceeded.
  Future<String?> createQuote({
    required String clientName,
    required String subject,
    required List<QuoteLine> lines,
    double labour = 0,
    bool useSignature = false,
    String templateId = 'classic',
    bool isPremium = false,
  }) async {
    final repo = ref.read(quoteRepositoryProvider);

    if (!isPremium) {
      final count = await repo.count();
      if (count >= kFreeQuotaLimit) return null; // quota exceeded
    }

    final now = DateTime.now();
    final quote = Quote(
      id: const Uuid().v4(),
      clientName: clientName,
      subject: subject,
      lines: lines,
      labour: labour,
      useSignature: useSignature,
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );

    await repo.save(quote);
    await reload();
    return quote.id;
  }

  Future<void> updateQuote(Quote quote) async {
    final updated = quote.copyWith(updatedAt: DateTime.now());
    await ref.read(quoteRepositoryProvider).save(updated);
    await reload();
  }

  Future<void> deleteQuote(String id) async {
    await ref.read(quoteRepositoryProvider).delete(id);
    await reload();
  }
}

final singleQuoteProvider =
    FutureProvider.family<Quote?, String>((ref, id) async {
  return ref.read(quoteRepositoryProvider).getById(id);
});
