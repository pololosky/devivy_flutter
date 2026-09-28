import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/quote_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quote.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  List<Quote> _filter(List<Quote> quotes) {
    if (_query.trim().isEmpty) return quotes;
    final q = _query.toLowerCase();
    return quotes.where((d) =>
        d.subject.toLowerCase().contains(q) ||
        d.clientName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesProvider);
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un devis...',
                  hintStyle: TextStyle(color: AppColors.textDark.withAlpha(140)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('Mes devis'),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search_outlined),
            tooltip: _searchOpen ? 'Fermer' : 'Rechercher',
            onPressed: _toggleSearch,
          ),
          if (!_searchOpen)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Paramètres',
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: quotesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (allQuotes) {
          final quotes = _filter(allQuotes);

          if (allQuotes.isEmpty) {
            return _EmptyState(onNew: () => context.push('/quotes/new'));
          }

          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off_outlined,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text('Aucun résultat pour "$_query"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                ]),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(quotesProvider.notifier).reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _QuoteCard(
                quote: quotes[index],
                currency: appState.currency,
                onTap: () => context.push('/quotes/${quotes[index].id}/preview'),
                onEdit: () =>
                    context.push('/quotes/${quotes[index].id}/edit'),
                onDelete: () =>
                    _confirmDelete(context, ref, quotes[index]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        height: 52,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final quotes = ref.read(quotesProvider).valueOrNull ?? [];
            if (!appState.isPremium && quotes.length >= kFreeQuotaLimit) {
              _showQuotaDialog(context);
              return;
            }
            context.push('/quotes/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouveau devis'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Quote quote) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: const Text('Supprimer ce devis ?'),
        content: Text(
          'Le devis « ${quote.subject} » pour ${quote.clientName} sera supprimé définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textDark)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(quotesProvider.notifier).deleteQuote(quote.id);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showQuotaDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: const Text('Limite atteinte'),
        content: Text(
          'Le mode gratuit vous limite à $kFreeQuotaLimit devis sauvegardés. Passez en Premium pour un accès illimité.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard',
                style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              GoRouter.of(ctx).push('/settings/premium');
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Voir Premium'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Quote Card ──────────────────────────────────────

String _currencySymbol(String code) {
  switch (code) {
    case 'USD': return '\$';
    case 'CNY': return '¥';
    case 'FCFA': return 'FCFA';
    default: return '€';
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Quote quote;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final symbol = _currencySymbol(currency);
    final amountStr =
        '${quote.total.toStringAsFixed(currency == 'FCFA' ? 0 : 2)} $symbol';

    final dateFormatter = DateFormat('dd MMM yyyy', 'fr_FR');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.subject,
                          style:
                              Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quote.clientName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textDark.withAlpha(160),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountStr,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.textDark.withAlpha(120),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(quote.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withAlpha(140),
                        ),
                  ),
                  const Spacer(),
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    label: 'Modifier',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.delete_outline,
                    label: 'Supprimer',
                    onTap: onDelete,
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Empty State ─────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun devis pour l\'instant',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier devis professionnel en quelques secondes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withAlpha(160),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau devis'),
            ),
          ],
        ),
      ),
    );
  }
}
