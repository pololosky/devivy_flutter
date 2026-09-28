import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/business_profile.dart';
import '../data/models/quote.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const _sage      = PdfColor(0.549, 0.612, 0.486);
const _sageLight = PdfColor(0.910, 0.918, 0.800);
const _textDark  = PdfColor(0.137, 0.157, 0.149);
const _textDeep  = PdfColor(0.075, 0.067, 0.078);
const _white     = PdfColors.white;
const _pageWhite = PdfColor(0.992, 0.992, 0.984);
const _divLine   = PdfColor(0.867, 0.878, 0.784);
// grey shades used instead of .flatten()
const _textMid   = PdfColor(0.420, 0.430, 0.420);   // ~textDark at 50%
const _textFaint = PdfColor(0.600, 0.608, 0.602);   // ~textDark at 60%

// ── Template catalogue (shared with picker UI) ────────────────────────────────
class TemplateInfo {
  const TemplateInfo(this.id, this.name, this.isPremium, this.description);
  final String id;
  final String name;
  final bool isPremium;
  final String description;
}

const kTemplates = <TemplateInfo>[
  TemplateInfo('sobre',       'Sobre',          false, 'Neutre et universel — idéal pour démarrer'),
  TemplateInfo('artisan',     'Artisan',        false, 'Formulaire traditionnel, fort contraste'),
  TemplateInfo('epure',       'Épuré',          false, 'Minimalisme maximal, espace blanc'),
  TemplateInfo('classique',   'Classique',      false, 'Administratif, double signature'),
  TemplateInfo('compact',     'Compact',        false, 'Optimisé pour les longs tableaux'),
  TemplateInfo('service',     'Service',        false, 'Objet mis en avant, orienté prestation'),
  TemplateInfo('numerote',    'Numéroté',       false, 'Lignes numérotées pour discussion client'),
  TemplateInfo('bandeau',     'Bandeau',        true,  'Large bandeau coloré en en-tête'),
  TemplateInfo('elegance',    'Élégance',       true,  'Typographie serif, style prestige'),
  TemplateInfo('deux_tons',   'Deux tons',      true,  'Bande latérale colorée pleine hauteur'),
  TemplateInfo('resume_tete', 'Résumé en tête', true,  'Montant total annoncé avant le tableau'),
];

// ── Service ────────────────────────────────────────────────────────────────────
class PdfService {

  // ── font loaders ──────────────────────────────────────────────────────────
  static Future<pw.Font> _font({bool bold = false}) async {
    final path = bold
        ? 'packages/google_fonts/fonts/DMSans-Bold.ttf'
        : 'packages/google_fonts/fonts/DMSans-Regular.ttf';
    try { return pw.Font.ttf(await rootBundle.load(path)); }
    catch (_) { return bold ? pw.Font.helveticaBold() : pw.Font.helvetica(); }
  }

  static Future<pw.Font> _serif({bool bold = false}) async {
    final path = bold
        ? 'packages/google_fonts/fonts/Lora-Bold.ttf'
        : 'packages/google_fonts/fonts/Lora-Regular.ttf';
    try { return pw.Font.ttf(await rootBundle.load(path)); }
    catch (_) { return bold ? pw.Font.timesBold() : pw.Font.times(); }
  }

  // ── public API ─────────────────────────────────────────────────────────────
  static Future<Uint8List> generate({
    required Quote quote,
    required BusinessProfile profile,
    String templateId = 'sobre',
    String currency = 'EUR',
  }) async {
    final r = await _font();
    final b = await _font(bold: true);
    final fmt = _buildFmt(currency);
    final logo = await _readImg(await _freshPath('logo.png') ?? profile.logoPath);
    final sig  = quote.useSignature
        ? await _readImg(await _freshPath('signature.png') ?? profile.signaturePath)
        : null;

    switch (templateId) {
      case 'artisan':    return _artisan(quote, profile, r, b, fmt, logo, sig);
      case 'epure':      return _epure(quote, profile, r, b, fmt, logo, sig);
      case 'classique':  return _classique(quote, profile, r, b, fmt, logo, sig);
      case 'compact':    return _compact(quote, profile, r, b, fmt, logo, sig);
      case 'service':    return _service(quote, profile, r, b, fmt, logo, sig);
      case 'numerote':   return _numerote(quote, profile, r, b, fmt, logo, sig);
      case 'bandeau':    return _bandeau(quote, profile, r, b, fmt, logo, sig);
      case 'elegance':   return _elegance(quote, profile, r, b, fmt, logo, sig,
                             await _serif(), await _serif(bold: true));
      case 'deux_tons':  return _deuxTons(quote, profile, r, b, fmt, logo, sig);
      case 'resume_tete':return _resumeTete(quote, profile, r, b, fmt, logo, sig);
      default:           return _sobre(quote, profile, r, b, fmt, logo, sig);
    }
  }

  static Future<File> saveToTemp(Uint8List bytes, String subject) async {
    final dir = await getTemporaryDirectory();
    final name = subject.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
    final file = File('${dir.path}/devis_$name.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  static String Function(double) _buildFmt(String currency) {
    final sym = _sym(currency);
    final dec = currency == 'FCFA' ? 0 : 2;
    return (v) => '${v.toStringAsFixed(dec).replaceAll('.', ',')} $sym';
  }
  static String _sym(String c) {
    switch (c) {
      case 'USD': return '\$'; case 'CNY': return 'CNY';
      case 'FCFA': return 'FCFA'; default: return 'EUR';
    }
  }
  static Future<String?> _freshPath(String filename) async {
    try {
      final f = File('${(await getApplicationDocumentsDirectory()).path}/$filename');
      return await f.exists() ? f.path : null;
    } catch (_) { return null; }
  }
  static Future<pw.MemoryImage?> _readImg(String? path) async {
    if (path == null) return null;
    try {
      final f = File(path);
      if (await f.exists()) return pw.MemoryImage(await f.readAsBytes());
    } catch (_) {}
    return null;
  }
  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
  static String _dateFr(DateTime d, {bool short = false}) =>
      short ? DateFormat('dd/MM/yyyy').format(d)
            : DateFormat('dd MMMM yyyy', 'fr_FR').format(d);

  // ── shared widgets ─────────────────────────────────────────────────────────
  static pw.Widget _tc(String t, pw.Font f, {
    bool bold = false, PdfColor? color,
    pw.Alignment align = pw.Alignment.centerLeft, double size = 9,
  }) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    alignment: align,
    child: pw.Text(t, style: pw.TextStyle(
      font: f, fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? _textDark,
    )),
  );

  static pw.Widget _tr(String label, String value, pw.Font f,
      {double size = 9, PdfColor? color}) =>
    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child:
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(font: f, fontSize: size, color: color ?? _textDark)),
        pw.Text(value, style: pw.TextStyle(font: f, fontSize: size, color: color ?? _textDark)),
      ]));

  static pw.Widget _table(Quote q, String Function(double) fmt,
      pw.Font r, pw.Font b, {
    PdfColor headerBg = _sageLight,
    PdfColor headerFg = _textDeep,
    PdfColor? rowOddBg,
    bool numbered = false,
    double rowSize = 9,
    double vPad = 5,
  }) {
    // Headers
    final headers = numbered
        ? ['N°', 'Designation', 'Qte', 'Prix unit.', 'Total']
        : ['Designation', 'Qte', 'Prix unit.', 'Total'];

    // Column widths as fractions of content width
    final columnWidths = numbered
        ? [0.05, 0.45, 0.10, 0.20, 0.20]
        : [0.45, 0.10, 0.23, 0.22];

    // Data rows
    final data = q.lines.asMap().entries.map((e) {
      final i = e.key;
      final l = e.value;
      if (numbered) {
        return ['${i + 1}', l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)];
      }
      return [l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        font: b, fontSize: rowSize,
        fontWeight: pw.FontWeight.bold, color: headerFg,
      ),
      cellStyle: pw.TextStyle(font: r, fontSize: rowSize, color: _textDark),
      headerDecoration: pw.BoxDecoration(color: headerBg),
      rowDecoration: rowOddBg != null
          ? pw.BoxDecoration(color: rowOddBg)
          : null,
      oddRowDecoration: rowOddBg != null
          ? const pw.BoxDecoration(color: PdfColors.white)
          : null,
      border: pw.TableBorder.all(color: _divLine, width: 0.5),
      cellPadding: pw.EdgeInsets.symmetric(horizontal: 7, vertical: vPad),
      columnWidths: columnWidths.asMap().map(
        (i, w) => MapEntry(i, pw.FlexColumnWidth(w * 10)),
      ),
      // Right-align numeric columns
      cellAlignments: numbered
          ? {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            }
          : {
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
      headerAlignments: numbered
          ? {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            }
          : {
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
    );
  }

  static pw.Widget _totals(Quote q, String Function(double) fmt,
      pw.Font r, pw.Font b, {
    double width = 200, PdfColor bg = _sageLight,
    PdfColor fgLabel = _textDeep, PdfColor fgTotal = _textDeep,
  }) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(children: [
        _tr('Sous-total', fmt(q.linesTotal), r),
        if (q.labour > 0) _tr("Main d'oeuvre", fmt(q.labour), r),
        pw.Divider(color: _divLine, height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('TOTAL HT', style: pw.TextStyle(font: b,
              fontWeight: pw.FontWeight.bold, fontSize: 11, color: fgLabel)),
          pw.Text(fmt(q.total), style: pw.TextStyle(font: b,
              fontWeight: pw.FontWeight.bold, fontSize: 12, color: fgTotal)),
        ]),
      ]),
    ),
  );

  static pw.Widget _sig(pw.MemoryImage? sig, pw.Font r,
      {String label = 'Signature :'}) =>
    pw.Align(alignment: pw.Alignment.centerRight,
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(label, style: pw.TextStyle(font: r, fontSize: 8, color: _textDark)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: 170, height: 72,
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _divLine, width: 0.5), color: _white),
          child: sig != null ? pw.Image(sig, fit: pw.BoxFit.contain) : pw.SizedBox(),
        ),
      ]),
    );

  // ══════════════════════════════════════════════════════════════════════════════
  // 1. SOBRE
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _sobre(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logo != null) ...[
            pw.Container(width: 60, height: 60, child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 6),
          ],
          pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 18,
              fontWeight: pw.FontWeight.bold, color: _textDeep)),
          if (p.slogan != null)
            pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 10,
                color: _sage, fontStyle: pw.FontStyle.italic)),
          pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 14),
        pw.Divider(color: _sageLight, thickness: 1.5),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 13,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
            pw.Text('Objet : ${q.subject}', style: pw.TextStyle(font: r, fontSize: 10, color: _textDark)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 18,
                color: _sage, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.Text(_dateFr(q.createdAt), style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
          ]),
        ]),
        pw.SizedBox(height: 16),
        _table(q, fmt, r, b),
        pw.SizedBox(height: 14),
        _totals(q, fmt, r, b),
        pw.SizedBox(height: 20),
        if (sigImg != null) _sig(sigImg, r),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 2. ARTISAN
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _artisan(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logo != null) ...[
            pw.Container(width: 56, height: 56, child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 6),
          ],
          pw.Text(p.businessName.toUpperCase(), style: pw.TextStyle(font: b, fontSize: 16,
              fontWeight: pw.FontWeight.bold, color: _textDeep, letterSpacing: 1.5)),
          if (p.slogan != null)
            pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 9,
                color: _textDark, fontStyle: pw.FontStyle.italic)),
          pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 6),
        pw.Divider(color: _textDeep, thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 12,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
            pw.Text('Objet : ${q.subject}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 20,
                fontWeight: pw.FontWeight.bold, color: _textDeep, letterSpacing: 2)),
            pw.Text(_dateFr(q.createdAt, short: true), style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
          ]),
        ]),
        pw.SizedBox(height: 14),
        _table(q, fmt, r, b, headerBg: _textDeep, headerFg: _white, rowOddBg: _pageWhite),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Container(width: 210, padding: const pw.EdgeInsets.all(12),
            color: _textDeep,
            child: pw.Column(children: [
              _tr('Sous-total', fmt(q.linesTotal), r, color: _white),
              if (q.labour > 0) _tr("Main d'oeuvre", fmt(q.labour), r, color: _white),
              pw.Divider(color: _sageLight, height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL HT', style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 12, color: _white)),
                pw.Text(fmt(q.total), style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 13, color: _white)),
              ]),
            ]),
          ),
        ),
        pw.SizedBox(height: 20),
        _sig(sigImg, r, label: 'Bon pour accord :'),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 3. ÉPURÉ
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _epure(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Container(width: 44, height: 44, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 10),
            ],
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.businessName, style: pw.TextStyle(font: r, fontSize: 14, color: _textDeep)),
              pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 8, color: _textMid)),
            ]),
          ]),
          pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 10,
              color: _sage, letterSpacing: 3, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 28),
        pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 12,
            fontWeight: pw.FontWeight.bold, color: _textDeep)),
        pw.Text(q.subject, style: pw.TextStyle(font: r, fontSize: 10, color: _textDark)),
        pw.Text(_dateFr(q.createdAt), style: pw.TextStyle(font: r, fontSize: 8, color: _textFaint)),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Designation', 'Qte', 'Prix unit.', 'Total'],
          data: q.lines.map((l) => [l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)]).toList(),
          headerStyle: pw.TextStyle(font: b, fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDeep),
          cellStyle: pw.TextStyle(font: r, fontSize: 9, color: _textDark),
          border: pw.TableBorder(
            top: const pw.BorderSide(color: _textDeep, width: 0.5),
            bottom: const pw.BorderSide(color: _textDeep, width: 0.5),
            horizontalInside: pw.BorderSide(color: _divLine, width: 0.3),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          columnWidths: const {0: pw.FlexColumnWidth(4.5), 1: pw.FlexColumnWidth(1.0), 2: pw.FlexColumnWidth(1.8), 3: pw.FlexColumnWidth(1.8)},
          cellAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          headerAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
        ),
        if (q.labour > 0) ...[
          pw.SizedBox(height: 8),
          pw.Align(alignment: pw.Alignment.centerRight,
              child: _tr("Main d'oeuvre", fmt(q.labour), r)),
        ],
        pw.SizedBox(height: 16),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text('TOTAL HT', style: pw.TextStyle(font: r, fontSize: 8,
                color: _textFaint, letterSpacing: 1)),
            pw.SizedBox(width: 12),
            pw.Text(fmt(q.total), style: pw.TextStyle(font: b, fontSize: 20,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
          ]),
        ),
        pw.SizedBox(height: 24),
        if (sigImg != null) _sig(sigImg, r),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 4. CLASSIQUE
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _classique(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Container(width: 52, height: 52, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 10),
            ],
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 14,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
              if (p.slogan != null)
                pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 8,
                    color: _textDark, fontStyle: pw.FontStyle.italic)),
              pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            ]),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 16,
                fontWeight: pw.FontWeight.bold, color: _sage, letterSpacing: 2)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _sageLight, width: 1)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Client : ${q.clientName}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
                pw.Text('Objet : ${q.subject}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
                pw.Text('Date : ${_dateFr(q.createdAt, short: true)}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
              ]),
            ),
          ]),
        ]),
        pw.SizedBox(height: 16),
        pw.Divider(color: _sageLight, thickness: 1),
        pw.SizedBox(height: 12),
        _table(q, fmt, r, b, headerBg: _sageLight, headerFg: _textDeep),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Container(width: 210, child: pw.Column(children: [
            pw.Divider(color: _textDeep, thickness: 1),
            pw.Divider(color: _textDeep, thickness: 0.3),
            if (q.labour > 0) ...[
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Main d'oeuvre", style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
                pw.Text(fmt(q.labour), style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
              ]),
            ],
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('TOTAL HT', style: pw.TextStyle(font: b, fontWeight: pw.FontWeight.bold, fontSize: 11, color: _textDeep)),
              pw.Text(fmt(q.total), style: pw.TextStyle(font: b, fontWeight: pw.FontWeight.bold, fontSize: 12, color: _textDeep)),
            ]),
            pw.Divider(color: _textDeep, thickness: 1),
            pw.Divider(color: _textDeep, thickness: 0.3),
          ])),
        ),
        pw.SizedBox(height: 20),
        pw.Row(children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("Signature de l'etablissement :", style: pw.TextStyle(font: r, fontSize: 8, color: _textDark)),
            pw.SizedBox(height: 4),
            pw.Container(width: 160, height: 64,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _divLine, width: 0.5), color: _white),
              child: sigImg != null ? pw.Image(sigImg, fit: pw.BoxFit.contain) : pw.SizedBox()),
          ])),
          pw.SizedBox(width: 20),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Signature du client :', style: pw.TextStyle(font: r, fontSize: 8, color: _textDark)),
            pw.SizedBox(height: 4),
            pw.Container(width: 160, height: 64,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _divLine, width: 0.5), color: _white),
              child: pw.SizedBox()),
          ])),
        ]),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 5. COMPACT
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _compact(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 30),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Container(width: 36, height: 36, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 8),
            ],
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 11,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
              pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 7.5, color: _textDark)),
            ]),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 14,
                color: _sage, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.Text(_dateFr(q.createdAt, short: true), style: pw.TextStyle(font: r, fontSize: 7.5, color: _textDark)),
          ]),
        ]),
        pw.SizedBox(height: 6),
        pw.Divider(color: _sageLight, height: 4),
        pw.SizedBox(height: 4),
        pw.Text('${q.clientName}  —  ${q.subject}',
            style: pw.TextStyle(font: r, fontSize: 8.5, color: _textDark)),
        pw.SizedBox(height: 8),
        _table(q, fmt, r, b, headerBg: _sageLight, headerFg: _textDeep,
            rowOddBg: _pageWhite, rowSize: 8, vPad: 3),
        pw.SizedBox(height: 8),
        _totals(q, fmt, r, b, width: 180),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text('Signature : ', style: pw.TextStyle(font: r, fontSize: 7, color: _textDark)),
            pw.Container(width: 100, height: 1, color: _divLine),
          ]),
        ),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 6. SERVICE
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _service(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Container(width: 52, height: 52, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 10),
            ],
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 15,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
              if (p.slogan != null)
                pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 9,
                    color: _sage, fontStyle: pw.FontStyle.italic)),
              pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            ]),
          ]),
          pw.Text(_dateFr(q.createdAt, short: true),
              style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 12),
        pw.Container(width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _sageLight,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Pour : ${q.clientName}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            pw.SizedBox(height: 2),
            pw.Text(q.subject, style: pw.TextStyle(font: b, fontSize: 13,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
          ]),
        ),
        pw.SizedBox(height: 16),
        _table(q, fmt, r, b, headerBg: _sage, headerFg: _white),
        pw.SizedBox(height: 14),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Container(width: 210,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: _sage, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(children: [
              if (q.labour > 0) ...[
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Main d'oeuvre", style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                  pw.Text(fmt(q.labour), style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                ]),
                pw.SizedBox(height: 4),
              ],
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL HT', style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 13, color: _white)),
                pw.Text(fmt(q.total), style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 14, color: _white)),
              ]),
            ]),
          ),
        ),
        pw.SizedBox(height: 16),
        if (sigImg != null) _sig(sigImg, r),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 7. NUMÉROTÉ
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _numerote(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logo != null) ...[
            pw.Container(width: 56, height: 56, child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 6),
          ],
          pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 18,
              fontWeight: pw.FontWeight.bold, color: _textDeep)),
          if (p.slogan != null)
            pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 10,
                color: _sage, fontStyle: pw.FontStyle.italic)),
          pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 14),
        pw.Divider(color: _sageLight, thickness: 1.5),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 12,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
            pw.Text('Objet : ${q.subject}', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
          ]),
          pw.Text(_dateFr(q.createdAt, short: true),
              style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 14),
        _table(q, fmt, r, b, headerBg: _textDeep, headerFg: _white, numbered: true),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Container(width: 210, color: _textDeep,
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(children: [
              if (q.labour > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Main d'oeuvre", style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                  pw.Text(fmt(q.labour), style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL HT', style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 12, color: _white)),
                pw.Text(fmt(q.total), style: pw.TextStyle(font: b,
                    fontWeight: pw.FontWeight.bold, fontSize: 13, color: _white)),
              ]),
            ]),
          ),
        ),
        pw.SizedBox(height: 20),
        if (sigImg != null) _sig(sigImg, r),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 8. BANDEAU (Premium)
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _bandeau(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [
        pw.Container(
          width: double.infinity, color: _sage,
          padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 24),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Row(children: [
              if (logo != null) ...[
                pw.Container(width: 56, height: 56, color: _white,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(logo, fit: pw.BoxFit.contain)),
                pw.SizedBox(width: 12),
              ],
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 18,
                    color: _white, fontWeight: pw.FontWeight.bold)),
                if (p.slogan != null)
                  pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 9,
                      color: _white, fontStyle: pw.FontStyle.italic)),
              ]),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 22,
                  color: _white, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
              pw.Text(_dateFr(q.createdAt, short: true),
                  style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
            ]),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(36, 22, 36, 32),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            pw.SizedBox(height: 14),
            pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 12,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
            pw.Text('Objet : ${q.subject}',
                style: pw.TextStyle(font: r, fontSize: 10, color: _textDark)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Designation', 'Qte', 'Prix unit.', 'Total'],
              data: q.lines.map((l) => [l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)]).toList(),
              headerStyle: pw.TextStyle(font: b, fontSize: 9, fontWeight: pw.FontWeight.bold, color: _sage),
              cellStyle: pw.TextStyle(font: r, fontSize: 9, color: _textDark),
              border: pw.TableBorder(
                bottom: const pw.BorderSide(color: _sage, width: 0.8),
                horizontalInside: pw.BorderSide(color: _divLine, width: 0.4),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              columnWidths: const {0: pw.FlexColumnWidth(4.5), 1: pw.FlexColumnWidth(1.0), 2: pw.FlexColumnWidth(1.8), 3: pw.FlexColumnWidth(1.8)},
              cellAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
              headerAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 16),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (sigImg != null) ...[
                pw.Expanded(child: _sig(sigImg, r)),
                pw.SizedBox(width: 16),
              ] else pw.Expanded(child: pw.SizedBox()),
              pw.Container(width: 210,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _sage, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(children: [
                  if (q.labour > 0) pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("Main d'oeuvre", style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                    pw.Text(fmt(q.labour), style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
                  ]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('TOTAL HT', style: pw.TextStyle(font: b,
                        fontWeight: pw.FontWeight.bold, fontSize: 13, color: _white)),
                    pw.Text(fmt(q.total), style: pw.TextStyle(font: b,
                        fontWeight: pw.FontWeight.bold, fontSize: 14, color: _white)),
                  ]),
                ]),
              ),
            ]),
            pw.SizedBox(height: 24),
            pw.Divider(color: _divLine),
            pw.SizedBox(height: 6),
            pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 8, color: _textFaint)),
          ]),
        ),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 9. ÉLÉGANCE (Premium)
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _elegance(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg,
      pw.Font serif, pw.Font serifB) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 40),
      build: (ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logo != null) ...[
            pw.Container(width: 60, height: 60, child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 8),
          ],
          pw.Text(p.businessName, style: pw.TextStyle(font: serifB, fontSize: 20,
              fontWeight: pw.FontWeight.bold, color: _textDeep)),
          if (p.slogan != null)
            pw.Text(p.slogan!, style: pw.TextStyle(font: serif, fontSize: 10,
                color: _sage, fontStyle: pw.FontStyle.italic)),
          pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
          pw.SizedBox(height: 8),
          pw.Container(width: 120, height: 0.8, color: _sage),
        ]),
        pw.SizedBox(height: 18),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(q.clientName, style: pw.TextStyle(font: serifB, fontSize: 12,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
            pw.Text(q.subject, style: pw.TextStyle(font: r, fontSize: 10, color: _textDark)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DEVIS', style: pw.TextStyle(font: r, fontSize: 10, color: _sage, letterSpacing: 4)),
            pw.Text(_dateFr(q.createdAt), style: pw.TextStyle(font: r, fontSize: 8, color: _textDark)),
          ]),
        ]),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['DESIGNATION', 'QTE', 'PRIX UNIT.', 'TOTAL'],
          data: q.lines.map((l) => [l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)]).toList(),
          headerStyle: pw.TextStyle(font: r, fontSize: 8, color: _textDark),
          cellStyle: pw.TextStyle(font: r, fontSize: 9, color: _textDark),
          border: pw.TableBorder(
            top: const pw.BorderSide(color: _textDeep, width: 0.5),
            bottom: const pw.BorderSide(color: _textDeep, width: 0.5),
            horizontalInside: pw.BorderSide(color: _divLine, width: 0.3),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          columnWidths: const {0: pw.FlexColumnWidth(4.5), 1: pw.FlexColumnWidth(1.0), 2: pw.FlexColumnWidth(1.8), 3: pw.FlexColumnWidth(1.8)},
          cellAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          headerAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Container(width: 210, padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _sage, width: 0.8)),
            child: pw.Column(children: [
              if (q.labour > 0) _tr("Main d'oeuvre", fmt(q.labour), r),
              pw.SizedBox(height: 4),
              pw.Text('TOTAL HT', style: pw.TextStyle(font: r, fontSize: 8,
                  letterSpacing: 2, color: _textDark)),
              pw.SizedBox(height: 3),
              pw.Text(fmt(q.total), style: pw.TextStyle(font: serifB, fontSize: 18,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
            ]),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Lu et approuve', style: pw.TextStyle(font: serif, fontSize: 8,
                color: _textDark, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 4),
            pw.Container(width: 170, height: 70,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _divLine, width: 0.5), color: _white),
              child: sigImg != null
                  ? pw.Image(sigImg, fit: pw.BoxFit.contain) : pw.SizedBox()),
          ]),
        ),
      ],
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 10. DEUX TONS (Premium)
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _deuxTons(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    const sideW = 130.0;
    const contentLeft = sideW + 20.0;
    const margin = 24.0;
    const pageH = 841.0; // A4

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Stack(children: [
        pw.Positioned.fill(child: pw.Container(color: _pageWhite)),
        // bande latérale
        pw.Positioned(left: 0, top: 0, bottom: 0,
          child: pw.Container(width: sideW, color: _sage)),
        // contenu bande
        pw.Positioned(
          left: 0, top: 0,
          child: pw.Container(
            width: sideW, height: pageH,
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  if (logo != null) ...[
                    pw.Container(width: 48, height: 48, color: _white,
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Image(logo, fit: pw.BoxFit.contain)),
                    pw.SizedBox(height: 8),
                  ],
                  pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 11,
                      color: _white, fontWeight: pw.FontWeight.bold)),
                  if (p.slogan != null) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 7.5,
                        color: _white, fontStyle: pw.FontStyle.italic)),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 7.5, color: _white)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(width: 80, height: 0.6, color: _white),
                  pw.SizedBox(height: 8),
                  pw.Text('TOTAL HT', style: pw.TextStyle(font: r, fontSize: 7.5,
                      color: _white, letterSpacing: 1)),
                  pw.SizedBox(height: 3),
                  pw.Text(fmt(q.total), style: pw.TextStyle(font: b, fontSize: 14,
                      fontWeight: pw.FontWeight.bold, color: _white)),
                ]),
              ],
            ),
          ),
        ),
        // contenu principal (droite)
        pw.Positioned(
          left: contentLeft, top: 32, right: margin,
          child: pw.SizedBox(
            width: PdfPageFormat.a4.width - contentLeft - margin,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('DEVIS', style: pw.TextStyle(font: b, fontSize: 20,
                    color: _sage, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
                pw.Text(_dateFr(q.createdAt, short: true),
                    style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
              ]),
              pw.SizedBox(height: 10),
              pw.Text(q.clientName, style: pw.TextStyle(font: b, fontSize: 12,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
              pw.Text(q.subject, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: ['Designation', 'Qte', 'Prix unit.', 'Total'],
                data: q.lines.map((l) => [l.name, _qty(l.quantity), fmt(l.unitPrice), fmt(l.total)]).toList(),
                headerStyle: pw.TextStyle(font: b, fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textDeep),
                cellStyle: pw.TextStyle(font: r, fontSize: 8, color: _textDark),
                headerDecoration: const pw.BoxDecoration(color: _sageLight),
                border: pw.TableBorder.all(color: _divLine, width: 0.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                columnWidths: const {0: pw.FlexColumnWidth(3.5), 1: pw.FlexColumnWidth(0.9), 2: pw.FlexColumnWidth(1.6), 3: pw.FlexColumnWidth(1.6)},
                cellAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
                headerAlignments: const {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
              ),
              if (q.labour > 0) ...[
                pw.SizedBox(height: 6),
                pw.Align(alignment: pw.Alignment.centerRight,
                  child: pw.Text("Main d'oeuvre : ${fmt(q.labour)}",
                      style: pw.TextStyle(font: r, fontSize: 8, color: _textDark))),
              ],
              pw.SizedBox(height: 16),
              if (sigImg != null) _sig(sigImg, r),
            ]),
          ),
        ),
      ]),
    ));
    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 11. RÉSUMÉ EN TÊTE (Premium)
  // ══════════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _resumeTete(Quote q, BusinessProfile p,
      pw.Font r, pw.Font b, String Function(double) fmt,
      pw.MemoryImage? logo, pw.MemoryImage? sigImg) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Container(width: 52, height: 52, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 10),
            ],
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.businessName, style: pw.TextStyle(font: b, fontSize: 15,
                  fontWeight: pw.FontWeight.bold, color: _textDeep)),
              if (p.slogan != null)
                pw.Text(p.slogan!, style: pw.TextStyle(font: r, fontSize: 9,
                    color: _sage, fontStyle: pw.FontStyle.italic)),
              pw.Text(p.address, style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            ]),
          ]),
          pw.Text(_dateFr(q.createdAt, short: true),
              style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
        ]),
        pw.SizedBox(height: 14),
        // Bandeau résumé — total en grand
        pw.Container(
          width: double.infinity, color: _sage,
          padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Pour : ${q.clientName}',
                  style: pw.TextStyle(font: r, fontSize: 9, color: _white)),
              pw.Text(q.subject, style: pw.TextStyle(font: b, fontSize: 11,
                  fontWeight: pw.FontWeight.bold, color: _white)),
            ]),
            pw.Text(fmt(q.total), style: pw.TextStyle(font: b, fontSize: 24,
                fontWeight: pw.FontWeight.bold, color: _white)),
          ]),
        ),
        pw.SizedBox(height: 16),
        _table(q, fmt, r, b, headerBg: _sageLight, headerFg: _textDeep),
        pw.SizedBox(height: 10),
        pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text('Total HT : ', style: pw.TextStyle(font: r, fontSize: 9, color: _textDark)),
            pw.Text(fmt(q.total), style: pw.TextStyle(font: b, fontSize: 10,
                fontWeight: pw.FontWeight.bold, color: _textDeep)),
          ]),
        ),
        pw.SizedBox(height: 20),
        if (sigImg != null) _sig(sigImg, r),
      ],
    ));
    return pdf.save();
  }
}
