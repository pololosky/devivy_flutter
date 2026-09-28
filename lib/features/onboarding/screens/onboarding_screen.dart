import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/business_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  bool _saving = false;
  String _currency = 'EUR';

  static const _currencies = [
    _CurrencyOption('EUR', '€', 'Euro'),
    _CurrencyOption('FCFA', 'FCFA', 'Franc CFA'),
    _CurrencyOption('USD', '\$', 'Dollar américain'),
    _CurrencyOption('CNY', '¥', 'Yuan chinois'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _sloganCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = BusinessProfile(
      businessName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      slogan: _sloganCtrl.text.trim().isEmpty ? null : _sloganCtrl.text.trim(),
    );

    await ref.read(profileProvider.notifier).save(profile);
    await ref.read(appStateProvider.notifier).completeOnboarding(currency: _currency);

    if (mounted) context.go('/quotes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Logo / branding area
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Bienvenue sur Devivy',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Commençons par configurer votre profil professionnel. Ces informations apparaîtront sur tous vos devis.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark.withAlpha(180),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 36),
                _SectionLabel('Votre établissement'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du business *',
                    hintText: 'ex : Plomberie Dupont',
                    prefixIcon: Icon(Icons.business_outlined,
                        color: AppColors.primary),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adresse *',
                    hintText: 'ex : 12 rue des Artisans, 75001 Paris',
                    prefixIcon:
                        Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sloganCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Slogan (facultatif)',
                    hintText: 'ex : La qualité à votre service',
                    prefixIcon: Icon(Icons.format_quote_outlined,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 28),
                _SectionLabel('Devise'),
                const SizedBox(height: 12),
                // Currency picker — 2×2 grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  children: _currencies.map((c) {
                    final selected = _currency == c.code;
                    return GestureDetector(
                      onTap: () => setState(() => _currency = c.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.surface : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.divider,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(
                              c.symbol,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.primary : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.code,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? AppColors.primary : AppColors.textDark,
                                      )),
                                  Text(c.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textDark.withAlpha(140),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text("Commencer à créer mes devis"),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Vous pourrez modifier ces informations à tout moment dans les paramètres.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withAlpha(140),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption(this.code, this.symbol, this.label);
  final String code;
  final String symbol;
  final String label;
}
