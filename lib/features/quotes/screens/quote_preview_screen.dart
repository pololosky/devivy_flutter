import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/quote_provider.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quote.dart';
import '../../../services/pdf_service.dart';
import '../widgets/template_picker_sheet.dart';

class QuotePreviewScreen extends ConsumerStatefulWidget {
  const QuotePreviewScreen({super.key, required this.quoteId});
  final String quoteId;

  @override
  ConsumerState<QuotePreviewScreen> createState() =>
      _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends ConsumerState<QuotePreviewScreen> {
  Uint8List? _pdfBytes;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generatePdf());
  }

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    final quote = await ref
        .read(quoteRepositoryProvider)
        .getById(widget.quoteId);
    if (quote == null || !mounted) return;

    // Always reload profile fresh to pick up any newly saved signature/logo
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    final currency = ref.read(appStateProvider).currency;

    // If a signature file exists on disk, force useSignature = true for rendering
    // (the quote flag may be stale if signature was added after quote creation)
    final sigPath = profile.signaturePath;
    Quote renderQuote = quote;
    if (sigPath != null && sigPath.isNotEmpty && !quote.useSignature) {
      final sigFile = File(sigPath);
      if (await sigFile.exists()) {
        renderQuote = quote.copyWith(useSignature: true);
      }
    }

    final bytes = await PdfService.generate(
      quote: renderQuote,
      profile: profile,
      templateId: quote.templateId,
      currency: currency,
    );

    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    }
  }

  Future<Quote?> _getQuote() =>
      ref.read(quoteRepositoryProvider).getById(widget.quoteId);

  Future<void> _download() async {
    final quote = await _getQuote();
    if (quote == null || _pdfBytes == null) return;
    final file = await PdfService.saveToTemp(_pdfBytes!, quote.subject);
    if (!mounted) return;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Devis - ${quote.subject}',
    );
  }

  Future<void> _print() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
  }

  Future<void> _share() async {
    final quote = await _getQuote();
    if (quote == null || _pdfBytes == null) return;
    final file = await PdfService.saveToTemp(_pdfBytes!, quote.subject);
    if (!mounted) return;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Devis - ${quote.subject}',
      text: 'Veuillez trouver ci-joint le devis pour : ${quote.subject}',
    );
  }

  Future<void> _changeTemplate() async {
    final quote = await _getQuote();
    if (quote == null || !mounted) return;

    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (!mounted) return;

    final newTemplate = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplatePickerSheet(
        currentTemplateId: quote.templateId,
        quote: quote,
        profile: profile,
      ),
    );

    if (newTemplate != null && newTemplate != quote.templateId) {
      final updated = quote.copyWith(templateId: newTemplate);
      await ref.read(quotesProvider.notifier).updateQuote(updated);
      await _generatePdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A3A3A),
      appBar: AppBar(
        backgroundColor: AppColors.textDeep,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('Aperçu du devis',
            style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          tooltip: 'Mes devis',
          onPressed: () => context.go('/quotes'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.white),
            tooltip: 'Modifier',
            onPressed: () =>
                context.push('/quotes/${widget.quoteId}/edit'),
          ),
        ],
      ),
      body: _generating
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _pdfBytes == null
              ? const Center(child: Text('Erreur de génération du PDF'))
              : PdfPreview(
                  build: (_) async => _pdfBytes!,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  pdfFileName: 'devis.pdf',
                  maxPageWidth: 800,
                  actions: const [],
                ),
      bottomNavigationBar: _generating
          ? null
          : Container(
              color: AppColors.textDeep,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.download_outlined,
                      label: 'Télécharger',
                      onTap: _download,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.print_outlined,
                      label: 'Imprimer',
                      onTap: _print,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Partager',
                      onTap: _share,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.style_outlined,
                      label: 'Template',
                      onTap: _changeTemplate,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
