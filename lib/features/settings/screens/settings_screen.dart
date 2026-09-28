import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Premium badge
          if (!appState.isPremium) _PremiumBanner(),

          const SizedBox(height: 16),

          // Profile section
          _SettingsSection(
            title: 'Mon établissement',
            tiles: [
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Profil / Établissement',
                subtitle: 'Nom, adresse, slogan',
                onTap: () => context.push('/settings/profile'),
              ),
              _SettingsTile(
                icon: Icons.draw_outlined,
                title: 'Signature',
                subtitle: 'Dessiner ou effacer ma signature',
                onTap: () => context.push('/settings/signature'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Preferences section
          _SettingsSection(
            title: 'Préférences',
            tiles: [
              _CurrencyTile(
                current: appState.currency,
                onChanged: (c) =>
                    ref.read(appStateProvider.notifier).setCurrency(c),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Account section
          _SettingsSection(
            title: 'Compte & Premium',
            tiles: [
              if (appState.isLoggedIn)
                _SettingsTile(
                  icon: Icons.account_circle_outlined,
                  title: appState.userEmail ?? 'Compte connecté',
                  subtitle: appState.isPremium ? '✓ Premium actif' : 'Mode gratuit',
                  onTap: null,
                )
              else
                _SettingsTile(
                  icon: Icons.login_outlined,
                  title: 'Se connecter',
                  subtitle: 'Pour la sync cloud et le Premium',
                  onTap: () => context.push('/login'),
                ),
              if (!appState.isPremium)
                _SettingsTile(
                  icon: Icons.star_outline,
                  title: 'Passer en Premium',
                  subtitle: 'Achat unique — illimité et sans pub',
                  onTap: () => context.push('/settings/premium'),
                  accent: true,
                ),
              if (appState.isLoggedIn)
                _SettingsTile(
                  icon: Icons.logout_outlined,
                  title: 'Se déconnecter',
                  subtitle: null,
                  onTap: () => _confirmLogout(context, ref),
                  isDestructive: true,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // About
          _SettingsSection(
            title: 'À propos',
            tiles: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Accords
          _SettingsSection(
            title: 'Accords',
            tiles: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                subtitle: null,
                onTap: () => context.push('/settings/legal/privacy'),
              ),
              _SettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Conditions d\'utilisation',
                subtitle: null,
                onTap: () => context.push('/settings/legal/terms'),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Mentions légales',
                subtitle: null,
                onTap: () => context.push('/settings/legal/mentions'),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vos devis locaux restent disponibles. La synchronisation cloud sera suspendue.',
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
              await ref.read(appStateProvider.notifier).logout();
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Widgets ──────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode gratuit',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Publicités actives · Limite de 5 devis',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withAlpha(160),
                        )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/settings/premium'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Upgrade',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.tiles});
  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        Container(
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
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool accent;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : accent
            ? AppColors.primary
            : AppColors.textDark;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withAlpha(140),
                  ))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
              color: AppColors.divider, size: 20)
          : null,
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('EUR', '€', 'Euro'),
    ('FCFA', 'FCFA', 'Franc CFA'),
    ('USD', '\$', 'Dollar américain'),
    ('CNY', '¥', 'Yuan chinois'),
  ];

  String get _label {
    for (final o in _options) {
      if (o.$1 == current) return '${o.$2}  ${o.$3}';
    }
    return current;
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Devise', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDeep)),
            const SizedBox(height: 12),
            ..._options.map((o) {
              final selected = o.$1 == current;
              return GestureDetector(
                onTap: () {
                  onChanged(o.$1);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surface : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(o.$2, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.textDark)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$1, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textDark)),
                          Text(o.$3, style: TextStyle(fontSize: 12, color: AppColors.textDark.withAlpha(150))),
                        ],
                      )),
                      if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _showPicker(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.currency_exchange, color: AppColors.primary, size: 20),
      ),
      title: const Text('Devise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      subtitle: Text(_label, style: TextStyle(fontSize: 13, color: AppColors.textDark.withAlpha(140))),
      trailing: const Icon(Icons.chevron_right, color: AppColors.divider, size: 20),
    );
  }
}
