import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/quote_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quote.dart';

class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({super.key, this.quoteId});
  final String? quoteId;

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _labourCtrl = TextEditingController(text: '0');

  List<_LineState> _lines = [];
  bool _useSignature = false;
  String _templateId = 'classic';
  bool _saving = false;
  bool _loaded = false;

  Quote? _originalQuote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    // Load profile to determine signature default
    final profile =
        await ref.read(profileRepositoryProvider).getProfile();

    if (widget.quoteId != null) {
      // Edit mode: load existing quote
      final quote = await ref
          .read(quoteRepositoryProvider)
          .getById(widget.quoteId!);
      if (quote != null && mounted) {
        _originalQuote = quote;
        _clientCtrl.text = quote.clientName;
        _subjectCtrl.text = quote.subject;
        _labourCtrl.text =
            quote.labour > 0 ? quote.labour.toStringAsFixed(2) : '0';
        _lines = quote.lines
            .map((l) => _LineState.fromLine(l))
            .toList();
        _useSignature = quote.useSignature;
        _templateId = quote.templateId;
      }
    } else {
      // New quote: signature checked by default if profile has one
      _useSignature = profile.hasSignature;
    }

    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _subjectCtrl.dispose();
    _labourCtrl.dispose();
    for (final l in _lines) {
      l.nameCtrl.dispose();
      l.priceCtrl.dispose();
      l.qtyCtrl.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lines.add(_LineState(id: const Uuid().v4()));
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _handleSignatureToggle(bool value) async {
    if (value) {
      final profile =
          await ref.read(profileRepositoryProvider).getProfile();
      if (!profile.hasSignature) {
        if (!mounted) return;
        _showNoSignatureDialog();
        return;
      }
    }
    setState(() => _useSignature = value);
  }

  void _showNoSignatureDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: const Text('Aucune signature enregistrée'),
        content: const Text(
          'Vous n\'avez pas encore de signature. Souhaitez-vous en créer une maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Auto-save current form before navigating
              await _autoSave();
              if (mounted) context.push('/settings/signature');
            },
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Créer ma signature'),
          ),
        ],
      ),
    );
  }

  /// Saves the current state silently (without validation) so data isn't lost
  Future<void> _autoSave() async {
    final lines = _buildLines();
    final labour =
        double.tryParse(_labourCtrl.text.replaceAll(',', '.')) ?? 0;

    if (_clientCtrl.text.trim().isEmpty &&
        _subjectCtrl.text.trim().isEmpty) return;

    final notifier = ref.read(quotesProvider.notifier);
    if (widget.quoteId != null && _originalQuote != null) {
      await notifier.updateQuote(_originalQuote!.copyWith(
        clientName: _clientCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        lines: lines,
        labour: labour,
        useSignature: _useSignature,
        templateId: _templateId,
      ));
    } else {
      final isPremium = ref.read(appStateProvider).isPremium;
      await notifier.createQuote(
        clientName: _clientCtrl.text.trim().isEmpty
            ? 'Client'
            : _clientCtrl.text.trim(),
        subject: _subjectCtrl.text.trim().isEmpty
            ? 'Devis'
            : _subjectCtrl.text.trim(),
        lines: lines,
        labour: labour,
        useSignature: _useSignature,
        templateId: _templateId,
        isPremium: isPremium,
      );
    }
  }

  List<QuoteLine> _buildLines() {
    return _lines
        .map((l) => QuoteLine(
              id: l.id,
              name: l.nameCtrl.text.trim(),
              unitPrice:
                  double.tryParse(l.priceCtrl.text.replaceAll(',', '.')) ??
                      0,
              quantity:
                  double.tryParse(l.qtyCtrl.text.replaceAll(',', '.')) ?? 1,
            ))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final lines = _buildLines();
    final labour =
        double.tryParse(_labourCtrl.text.replaceAll(',', '.')) ?? 0;
    final isPremium = ref.read(appStateProvider).isPremium;
    final notifier = ref.read(quotesProvider.notifier);

    String? savedId;

    if (widget.quoteId != null && _originalQuote != null) {
      final updated = _originalQuote!.copyWith(
        clientName: _clientCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        lines: lines,
        labour: labour,
        useSignature: _useSignature,
        templateId: _templateId,
      );
      await notifier.updateQuote(updated);
      savedId = updated.id;
    } else {
      savedId = await notifier.createQuote(
        clientName: _clientCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        lines: lines,
        labour: labour,
        useSignature: _useSignature,
        templateId: _templateId,
        isPremium: isPremium,
      );
      if (savedId == null && mounted) {
        _showQuotaError();
        setState(() => _saving = false);
        return;
      }
    }

    if (mounted && savedId != null) {
      context.go('/quotes/$savedId/preview');
    }
  }

  void _showQuotaError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Limite de $kFreeQuotaLimit devis atteinte. Passez en Premium.',
        ),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Premium',
          textColor: AppColors.white,
          onPressed: () => context.push('/settings/premium'),
        ),
      ),
    );
  }

  double get _linesTotal =>
      _lines.fold(0, (sum, l) {
        final price =
            double.tryParse(l.priceCtrl.text.replaceAll(',', '.')) ?? 0;
        final qty =
            double.tryParse(l.qtyCtrl.text.replaceAll(',', '.')) ?? 1;
        return sum + price * qty;
      });

  double get _labour =>
      double.tryParse(_labourCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _total => _linesTotal + (_labour > 0 ? _labour : 0);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.quoteId != null;
    final currency = ref.watch(appStateProvider).currency;
    final currencySymbol = _symbolFor(currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le devis' : 'Nouveau devis'),
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _SectionCard(
                    title: 'Informations générales',
                    children: [
                      TextFormField(
                        controller: _clientCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom du client *',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Objet du devis *',
                          hintText:
                              'ex : Pose de carrelage salle de bain',
                          prefixIcon: Icon(Icons.subject_outlined,
                              color: AppColors.primary),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Prestations / produits',
                    children: [
                      if (_lines.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Aucune prestation ajoutée.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textDark
                                        .withAlpha(140)),
                          ),
                        ),
                      ...List.generate(_lines.length, (i) {
                        return _LineRow(
                          key: ValueKey(_lines[i].id),
                          line: _lines[i],
                          onRemove: () => _removeLine(i),
                          onChanged: () => setState(() {}),
                        );
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nouveau champ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Options',
                    children: [
                      // Signature checkbox
                      _CheckboxTile(
                        value: _useSignature,
                        label: 'Mettre ma signature',
                        onChanged: _handleSignatureToggle,
                      ),
                      const Divider(height: 20),
                      // Labour
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Main d\'œuvre ($currencySymbol)',
                              style:
                                  Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: _labourCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'))
                              ],
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixText: currencySymbol,
                              ),
                              textAlign: TextAlign.right,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Total summary
                  _TotalSummary(
                    linesTotal: _linesTotal,
                    labour: _labour,
                    total: _total,
                    currencySymbol: currencySymbol,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white),
                          )
                        : const Text('Enregistrer le devis'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────── Supporting widgets ──────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LineState {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;

  _LineState({
    required this.id,
    String name = '',
    String price = '',
    String qty = '1',
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price),
        qtyCtrl = TextEditingController(text: qty);

  factory _LineState.fromLine(QuoteLine line) => _LineState(
        id: line.id,
        name: line.name,
        price: line.unitPrice > 0 ? line.unitPrice.toStringAsFixed(2) : '',
        qty: line.quantity.toStringAsFixed(
            line.quantity == line.quantity.truncateToDouble() ? 0 : 2),
      );

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.onRemove,
    required this.onChanged,
  });

  final _LineState line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: line.nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Prestation / produit',
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => onChanged(),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            child: TextFormField(
              controller: line.qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: const InputDecoration(
                hintText: 'Qté',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: line.priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: const InputDecoration(
                hintText: 'Prix',
                suffixText: '',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              textAlign: TextAlign.right,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
          const Icon(Icons.draw_outlined,
              size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({
    required this.linesTotal,
    required this.labour,
    required this.total,
    required this.currencySymbol,
  });

  final double linesTotal;
  final double labour;
  final double total;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final decimals = currencySymbol == 'FCFA' ? 0 : 2;
    final fmt = (double v) =>
        '${v.toStringAsFixed(decimals).replaceAll('.', ',')} $currencySymbol';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TotalRow('Sous-total prestations', fmt(linesTotal)),
          if (labour > 0) ...[
            const SizedBox(height: 6),
            _TotalRow('Main d\'œuvre', fmt(labour)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total HT',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDeep,
                      )),
              Text(fmt(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                )),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

String _symbolFor(String code) {
  switch (code) {
    case 'USD': return '\$';
    case 'CNY': return '¥';
    case 'FCFA': return 'FCFA';
    default: return '€';
  }
}
