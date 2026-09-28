import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum LegalPage { privacy, terms, mentions }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final LegalPage page;

  String get _title => switch (page) {
        LegalPage.privacy  => 'Politique de confidentialité',
        LegalPage.terms    => 'Conditions d\'utilisation',
        LegalPage.mentions => 'Mentions légales',
      };

  List<_Section> get _sections => switch (page) {
        LegalPage.privacy  => _privacySections,
        LegalPage.terms    => _termsSections,
        LegalPage.mentions => _mentionsSections,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _sections.length,
        itemBuilder: (context, i) {
          final s = _sections[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.title != null) ...[
                  Text(
                    s.title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  s.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section {
  const _Section({this.title, required this.body});
  final String? title;
  final String body;
}

// ── Politique de confidentialité ──────────────────────────────────────────────
const _privacySections = <_Section>[
  _Section(
    body: 'Dernière mise à jour : septembre 2026',
  ),
  _Section(
    title: 'Données collectées',
    body:
        'Devivy fonctionne en priorité hors connexion. Les données que vous '
        'saisissez (profil établissement, devis) sont stockées localement sur '
        'votre appareil et ne sont jamais transmises à des tiers sans votre '
        'consentement explicite.\n\n'
        'Si vous créez un compte, votre adresse e-mail et un mot de passe '
        'chiffré sont conservés sur nos serveurs pour vous permettre de '
        'synchroniser vos devis et d\'accéder à la version Premium.',
  ),
  _Section(
    title: 'Données analytiques',
    body:
        'Avec votre accord, nous collectons des données d\'usage anonymisées '
        '(modèle d\'appareil, pays déduit de la configuration système) à des '
        'fins statistiques internes. Ces données ne permettent pas de vous '
        'identifier personnellement et ne sont pas revendues.',
  ),
  _Section(
    title: 'Stockage et sécurité',
    body:
        'Les données cloud sont stockées sur des serveurs sécurisés. Les mots '
        'de passe sont hachés avec bcrypt avant stockage. Aucune donnée de '
        'paiement n\'est conservée sur nos serveurs — les transactions sont '
        'gérées par Stripe conformément à leurs propres politiques de sécurité.',
  ),
  _Section(
    title: 'Vos droits',
    body:
        'Conformément au RGPD, vous disposez d\'un droit d\'accès, de '
        'rectification et de suppression de vos données. Pour exercer ces '
        'droits, contactez-nous via les paramètres de l\'application.',
  ),
  _Section(
    title: 'Contact',
    body: 'Pour toute question relative à la confidentialité, contactez-nous '
        'depuis la section "Compte" des paramètres.',
  ),
];

// ── Conditions d'utilisation ──────────────────────────────────────────────────
const _termsSections = <_Section>[
  _Section(
    body: 'Dernière mise à jour : septembre 2026',
  ),
  _Section(
    title: 'Acceptation des conditions',
    body:
        'En utilisant Devivy, vous acceptez les présentes conditions '
        'd\'utilisation. Si vous n\'acceptez pas ces conditions, vous ne devez '
        'pas utiliser l\'application.',
  ),
  _Section(
    title: 'Description du service',
    body:
        'Devivy est une application de création de devis professionnels '
        'destinée aux indépendants, artisans et petites entreprises. '
        'L\'application est disponible en version gratuite (avec publicités et '
        'quota de documents) et en version Premium (achat unique).',
  ),
  _Section(
    title: 'Utilisation autorisée',
    body:
        'Vous vous engagez à utiliser Devivy uniquement à des fins légales et '
        'professionnelles légitimes. Il est interdit d\'utiliser l\'application '
        'pour générer des documents frauduleux ou trompeurs.',
  ),
  _Section(
    title: 'Achat Premium',
    body:
        'L\'achat Premium est un paiement unique non remboursable après '
        'confirmation. Il donne accès à vie aux fonctionnalités Premium sur le '
        'compte associé, sans abonnement récurrent.',
  ),
  _Section(
    title: 'Propriété intellectuelle',
    body:
        'Les templates de documents, le design et le code de Devivy sont '
        'protégés par le droit d\'auteur. Les documents que vous créez avec '
        'l\'application vous appartiennent entièrement.',
  ),
  _Section(
    title: 'Limitation de responsabilité',
    body:
        'Devivy est fourni "tel quel". Nous ne garantissons pas que '
        'l\'application sera exempte d\'erreurs. Nous déclinons toute '
        'responsabilité quant à la conformité légale des devis que vous générez '
        'dans votre pays ou secteur d\'activité.',
  ),
];

// ── Mentions légales ──────────────────────────────────────────────────────────
const _mentionsSections = <_Section>[
  _Section(
    title: 'Éditeur de l\'application',
    body:
        'Devivy est une application indépendante.\n'
        'Pour nous contacter : via la section Compte dans les paramètres.',
  ),
  _Section(
    title: 'Hébergement',
    body:
        'Les données cloud de Devivy sont hébergées sur des serveurs sécurisés '
        'en Europe, conformément aux exigences du RGPD.',
  ),
  _Section(
    title: 'Propriété intellectuelle',
    body:
        'L\'ensemble des éléments constituant l\'application Devivy '
        '(design, code, templates, textes) est protégé par les lois relatives '
        'à la propriété intellectuelle. Toute reproduction sans autorisation '
        'est interdite.',
  ),
  _Section(
    title: 'Données personnelles',
    body:
        'Conformément à la loi Informatique et Libertés et au Règlement '
        'Général sur la Protection des Données (RGPD), vous disposez d\'un '
        'droit d\'accès, de rectification et de suppression des données vous '
        'concernant.',
  ),
  _Section(
    title: 'Droit applicable',
    body:
        'Les présentes mentions légales sont soumises au droit français. '
        'En cas de litige, les tribunaux français seront compétents.',
  ),
];
