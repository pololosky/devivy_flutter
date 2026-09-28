import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final List<List<Offset?>> _strokes = [];
  bool _saving = false;
  String? _existingPath;

  // Taille réelle du canvas widget (récupérée via GlobalKey)
  final _canvasKey = GlobalKey();
  Size _canvasSize = const Size(400, 150);

  @override
  void initState() {
    super.initState();
    _loadExisting();
    // Récupérer la taille après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCanvas());
  }

  void _measureCanvas() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() => _canvasSize = box.size);
    }
  }

  Future<void> _loadExisting() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    setState(() => _existingPath = profile.signaturePath);
  }

  void _onPanStart(DragStartDetails d) {
    setState(() => _strokes.add([d.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _strokes.last.add(null));
  }

  void _clear() => setState(() => _strokes.clear());

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dessinez votre signature d\'abord')),
      );
      return;
    }
    setState(() => _saving = true);

    // ── Rendu haute résolution ──────────────────────────────────────────────
    // On rend à 2× la taille du canvas pour avoir une bonne résolution PDF
    const exportW = 600.0;
    final exportH = (_canvasSize.height / _canvasSize.width * exportW).clamp(100.0, 300.0);
    final scaleX = exportW / _canvasSize.width;
    final scaleY = exportH / _canvasSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, exportW, exportH));

    // Fond blanc (visible dans le PDF et sans artefact de transparence)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, exportW, exportH),
      Paint()..color = Colors.white,
    );

    // Traits de la signature mis à l'échelle
    final paint = Paint()
      ..color = const Color(0xFF131114) // AppColors.textDeep
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      final path = Path();
      bool started = false;
      for (final pt in stroke) {
        if (pt == null) {
          started = false;
          continue;
        }
        final scaled = Offset(pt.dx * scaleX, pt.dy * scaleY);
        if (!started) {
          path.moveTo(scaled.dx, scaled.dy);
          started = true;
        } else {
          path.lineTo(scaled.dx, scaled.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(exportW.toInt(), exportH.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/signature.png');
    await file.writeAsBytes(bytes);

    await ref.read(profileProvider.notifier).saveSignature(file.path);

    if (mounted) {
      setState(() {
        _saving = false;
        _existingPath = file.path;
        _strokes.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature enregistrée'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
    await ref.read(profileProvider.notifier).saveSignature(null);
    if (_existingPath != null) {
      final f = File(_existingPath!);
      if (await f.exists()) await f.delete();
    }
    setState(() {
      _strokes.clear();
      _existingPath = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature supprimée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma signature'),
        actions: [
          if (_existingPath != null || _strokes.isNotEmpty)
            TextButton(
              onPressed: _delete,
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dessinez votre signature ci-dessous',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text('Elle sera utilisée automatiquement sur vos devis.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withAlpha(160))),
            const SizedBox(height: 16),

            // ── Canvas de saisie ────────────────────────────────────────────
            Expanded(
              child: Container(
                key: _canvasKey,
                decoration: BoxDecoration(
                  color: Colors.white, // fond blanc explicite
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _SignaturePainter(_strokes),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Aperçu signature existante ──────────────────────────────────
            if (_existingPath != null && _strokes.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Signature enregistrée — dessinez pour remplacer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary)),
                  ),
                  Image.file(File(_existingPath!),
                      height: 40,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ]),
              ),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _strokes.isEmpty ? null : _clear,
                  child: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving || _strokes.isEmpty ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.white))
                      : const Text('Enregistrer la signature'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);
  final List<List<Offset?>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDeep
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final path = Path();
      bool started = false;
      for (final pt in stroke) {
        if (pt == null) { started = false; continue; }
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
