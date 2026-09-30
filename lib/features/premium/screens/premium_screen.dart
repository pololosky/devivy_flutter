import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _purchasing = false;

  Future<void> _purchase() async {
    final appState = ref.read(appStateProvider);
    if (!appState.isLoggedIn) {
      // Need to be logged in to purchase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connectez-vous pour acheter le Premium'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'Se connecter',
            textColor: AppColors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    setState(() => _purchasing = true);
    try {
      final success = await ApiService.confirmPremium();
      if (success && mounted) {
        await ref.read(appStateProvider.notifier).setPremium(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Bienvenue en Premium !'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du paiement. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    if (appState.isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 64),
                const SizedBox(height: 16),
                Text('Vous êtes Premium !',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Vous bénéficiez de tous les avantages : devis illimités, sans publicité, templates premium inclus.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark.withAlpha(180),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Passer en Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          // Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_outline,
                    color: AppColors.primary, size: 52),
                const SizedBox(height: 12),
                Text(
                  'Devivy Premium',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Achat unique — pas d\'abonnement',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withAlpha(160),
                      ),
                ),
                const SizedBox(height: 20),
                const _PriceTag(),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text('Ce que vous obtenez',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),

          const _FeatureTile(
            icon: Icons.all_inclusive,
            title: 'Devis illimités',
            description:
                'Créez autant de devis que vous le souhaitez, sans restriction.',
          ),
          const _FeatureTile(
            icon: Icons.block,
            title: 'Sans publicité',
            description: 'Une expérience épurée, sans interruption.',
          ),
          const _FeatureTile(
            icon: Icons.style_outlined,
            title: 'Templates Premium',
            description:
                'Accédez à tous les templates de mise en page, y compris les exclusifs.',
          ),
          const _FeatureTile(
            icon: Icons.cloud_sync_outlined,
            title: 'Synchronisation cloud',
            description:
                'Sauvegardez vos devis en ligne et retrouvez-les sur tous vos appareils.',
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _purchasing ? null : _purchase,
            child: _purchasing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.white))
                : const Text('Acheter maintenant'),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Paiement sécurisé via Stripe. Aucun remboursement après achat.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withAlpha(120),
                  ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '9,99 €',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            'une seule fois',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withAlpha(200),
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withAlpha(160),
                          height: 1.4,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
