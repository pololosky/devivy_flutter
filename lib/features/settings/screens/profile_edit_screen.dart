import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/business_profile.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  String? _logoPath;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    _nameCtrl.text = profile.businessName;
    _addressCtrl.text = profile.address;
    _sloganCtrl.text = profile.slogan ?? '';
    _logoPath = profile.logoPath;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _sloganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    // Copy to app documents directory for persistence
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/logo.png');
    await File(picked.path).copy(dest.path);

    setState(() => _logoPath = dest.path);
  }

  Future<void> _removeLogo() async {
    if (_logoPath != null) {
      final f = File(_logoPath!);
      if (await f.exists()) await f.delete();
    }
    setState(() => _logoPath = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final current = await ref.read(profileRepositoryProvider).getProfile();
    final updated = BusinessProfile(
      businessName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      slogan: _sloganCtrl.text.trim().isEmpty ? null : _sloganCtrl.text.trim(),
      signaturePath: current.signaturePath,
      logoPath: _logoPath,
    );

    await ref.read(profileProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.primary),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil établissement')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Logo ────────────────────────────────────────────────
                  _SectionLabel('Logo'),
                  const SizedBox(height: 10),
                  _LogoPicker(
                    logoPath: _logoPath,
                    onPick: _pickLogo,
                    onRemove: _removeLogo,
                  ),
                  const SizedBox(height: 22),

                  // ── Infos ────────────────────────────────────────────────
                  _SectionLabel('Informations'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du business *',
                      prefixIcon: Icon(Icons.business_outlined, color: AppColors.primary),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sloganCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Slogan (facultatif)',
                      prefixIcon: Icon(Icons.format_quote_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                        : const Text('Enregistrer les modifications'),
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

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600),
      );
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.logoPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? logoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Preview
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: logoPath != null && File(logoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(File(logoPath!), fit: BoxFit.contain),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.primary, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logoPath != null ? 'Logo enregistré' : 'Aucun logo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Apparait en en-tête de vos devis.\nFormats: JPG, PNG — recommandé: fond transparent.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withAlpha(150), height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SmallBtn(label: logoPath != null ? 'Changer' : 'Choisir', onTap: onPick),
                    if (logoPath != null) ...[
                      const SizedBox(width: 8),
                      _SmallBtn(label: 'Supprimer', onTap: onRemove, destructive: true),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.label, required this.onTap, this.destructive = false});
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}
