# Devivy — Application Mobile Flutter

Application mobile Android/iOS de création de devis professionnels pour indépendants, artisans et petites entreprises. **Offline-first** : toutes les fonctionnalités essentielles fonctionnent sans connexion internet.

---

## Table des matières

1. [Stack technique](#stack-technique)
2. [Prérequis](#prérequis)
3. [Installation](#installation)
4. [Lancement](#lancement)
5. [Build production](#build-production)
6. [Architecture du projet](#architecture-du-projet)
7. [Fonctionnalités](#fonctionnalités)
8. [Navigation & routes](#navigation--routes)
9. [Modèle de données](#modèle-de-données)
10. [État global (Riverpod)](#état-global-riverpod)
11. [Génération PDF & templates](#génération-pdf--templates)
12. [Connexion au backend FastAPI](#connexion-au-backend-fastapi)
13. [Charte graphique](#charte-graphique)
14. [Comportement offline / online](#comportement-offline--online)
15. [Modèle économique côté app](#modèle-économique-côté-app)
16. [Configuration Android](#configuration-android)
17. [Points connus / TODO](#points-connus--todo)

---

## Stack technique

| Élément | Technologie | Version |
|---|---|---|
| Framework | Flutter | SDK `^3.10.0` |
| State management | Riverpod | `^2.6.1` |
| Navigation | go_router | `^14.8.1` |
| Stockage local | sqflite | `^2.4.2` |
| Préférences | shared_preferences | `^2.3.5` |
| Génération PDF | pdf + printing | `^3.11.3` / `^5.14.2` |
| Partage | share_plus | `^10.1.4` |
| Police | google_fonts (DM Sans) | `^6.2.1` |
| HTTP client | http | `^1.2.2` |
| Sélection d'image | image_picker | `^1.1.2` |
| UUID | uuid | `^4.5.1` |
| Localisation | intl | `^0.20.2` |

---

## Prérequis

- **Flutter SDK** 3.10+ → [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Android Studio** (émulateur Android) ou **Xcode** (iOS, macOS requis)
- **Android SDK** avec `minSdk = 21` (Android 5.0+)
- Mode développeur Windows activé (requis pour les symlinks Flutter) :
  ```
  Paramètres → Mise à jour et sécurité → Pour les développeurs → Mode développeur : ON
  ```

---

## Installation

```bash
cd front_flutter_devis_app

# Télécharger toutes les dépendances
flutter pub get
```

---

## Lancement

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil/émulateur spécifique
flutter run

# Cibler Android explicitement
flutter run -d android

# Cibler iOS (macOS requis)
flutter run -d ios

# Mode release
flutter run --release
```

> **URL du backend :** avant de lancer, vérifiez l'URL dans `lib/services/api_service.dart` :
> ```dart
> static const String baseUrl = 'http://10.0.2.2:8000'; // émulateur Android
> // Pour appareil physique : 'http://192.168.x.x:8000'
> ```

---

## Build production

```bash
# APK Android (installation directe)
flutter build apk --release

# App Bundle Android (Google Play Store)
flutter build appbundle --release

# iOS (nécessite macOS + Xcode + compte développeur Apple)
flutter build ios --release
```

---

## Architecture du projet

```
lib/
├── main.dart                              # Point d'entrée : ProviderScope, thème, router, locale FR
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart                # Palette AppColors, ThemeData complet (Material 3)
│   ├── router/
│   │   └── app_router.dart               # GoRouter — définition de toutes les routes
│   └── providers/
│       ├── app_state_provider.dart       # État global : onboarding, auth JWT, premium, devise
│       ├── quote_provider.dart           # CRUD devis + contrôle quota gratuit
│       └── profile_provider.dart        # Profil établissement (lecture/écriture)
│
├── data/
│   ├── models/
│   │   ├── quote.dart                    # Modèles Quote + QuoteLine (JSON/SQLite)
│   │   └── business_profile.dart        # Modèle profil (SharedPreferences)
│   ├── database/
│   │   └── database_helper.dart         # SQLite (sqflite) — CRUD bas niveau
│   └── repositories/
│       ├── quote_repository.dart        # Abstraction CRUD devis
│       └── profile_repository.dart      # Abstraction profil + logo + signature
│
├── services/
│   ├── pdf_service.dart                  # Génération PDF (11 templates), partage, sauvegarde
│   └── api_service.dart                  # Client HTTP vers le backend FastAPI
│
└── features/
    ├── onboarding/
    │   └── screens/
    │       └── onboarding_screen.dart    # 1er lancement : profil + choix de devise
    ├── quotes/
    │   ├── screens/
    │   │   ├── quotes_list_screen.dart   # Page principale — liste + recherche
    │   │   ├── quote_form_screen.dart    # Création / édition d'un devis
    │   │   └── quote_preview_screen.dart # Aperçu PDF + télécharger/imprimer/partager
    │   └── widgets/
    │       └── template_picker_sheet.dart # Bottom sheet de sélection de template
    ├── settings/
    │   └── screens/
    │       ├── settings_screen.dart      # Page paramètres principale
    │       ├── profile_edit_screen.dart  # Modifier profil + logo
    │       ├── signature_screen.dart     # Dessin et enregistrement de signature
    │       └── legal_screen.dart         # Pages légales (CGU, confidentialité, mentions)
    ├── auth/
    │   └── screens/
    │       ├── login_screen.dart         # Connexion compte
    │       └── register_screen.dart      # Création de compte
    └── premium/
        └── screens/
            └── premium_screen.dart       # Page achat Premium (Stripe)
```

---

## Fonctionnalités

### Gestion des devis
- **Création** : client, objet, lignes dynamiques (désignation + quantité + prix unitaire), main d'œuvre optionnelle, signature
- **Édition** : pré-remplissage complet, sauvegarde automatique avant navigation
- **Suppression** : confirmation obligatoire avant suppression définitive
- **Recherche** : filtrage temps réel par objet ou nom de client (AppBar)
- **Quota gratuit** : limité à **5 devis** (constante `kFreeQuotaLimit` dans `quote_provider.dart`)

### Profil établissement
- Nom du business, adresse, slogan (facultatif)
- **Logo** : sélection depuis la galerie, sauvegardé dans les documents de l'app
- **Signature manuscrite** : canvas tactile, export PNG, réutilisée sur les devis

### Génération de documents
- **11 templates** (7 gratuits + 4 premium) — voir section [Templates](#génération-pdf--templates)
- Export PDF, impression directe, partage (WhatsApp, e-mail, etc.)
- Prise en charge des **4 devises** : EUR, FCFA, USD, CNY
- Tableau paginé : les devis longs s'étalent sur plusieurs pages sans couper le contenu

### Paramètres
- Profil établissement (nom, adresse, slogan, logo)
- Signature manuscrite
- Devise (EUR / FCFA / USD / CNY)
- Compte & Premium (connexion, achat)
- Pages légales (Politique de confidentialité, CGU, Mentions légales)

### Authentification & cloud (optionnel)
- Inscription / connexion par email+mot de passe
- JWT stocké dans SharedPreferences
- Synchronisation cloud des devis si connecté
- Achat Premium via le backend (Stripe)

---

## Navigation & routes

Toutes les routes sont définies dans `lib/core/router/app_router.dart` via `go_router` :

| Route | Écran | Description |
|---|---|---|
| `/onboarding` | `OnboardingScreen` | Premier lancement uniquement |
| `/quotes` | `QuotesListScreen` | Page principale |
| `/quotes/new` | `QuoteFormScreen` | Nouveau devis |
| `/quotes/:id/edit` | `QuoteFormScreen(quoteId)` | Édition |
| `/quotes/:id/preview` | `QuotePreviewScreen` | Aperçu PDF |
| `/settings` | `SettingsScreen` | Paramètres |
| `/settings/profile` | `ProfileEditScreen` | Éditer profil + logo |
| `/settings/signature` | `SignatureScreen` | Dessiner signature |
| `/settings/premium` | `PremiumScreen` | Achat Premium |
| `/settings/legal/privacy` | `LegalScreen(privacy)` | Politique de confidentialité |
| `/settings/legal/terms` | `LegalScreen(terms)` | Conditions d'utilisation |
| `/settings/legal/mentions` | `LegalScreen(mentions)` | Mentions légales |
| `/login` | `LoginScreen` | Connexion |
| `/register` | `RegisterScreen` | Inscription |

**Redirection initiale :** si `isOnboarded = false` → `/onboarding`, sinon → `/quotes`.

---

## Modèle de données

### `Quote`
```dart
Quote {
  id: String           // UUID v4 généré localement
  clientName: String   // Nom du client
  subject: String      // Objet du devis
  lines: List<QuoteLine>
  labour: double       // Main d'œuvre (0 = masquée sur le PDF)
  useSignature: bool   // Afficher la signature sur ce devis
  templateId: String   // ID du template PDF sélectionné
  createdAt: DateTime
  updatedAt: DateTime
  remoteId: String?    // ID backend pour la sync cloud
}
```

### `QuoteLine`
```dart
QuoteLine {
  id: String
  name: String       // Désignation de la prestation/produit
  unitPrice: double  // Prix unitaire
  quantity: double   // Quantité (défaut : 1)
  // total = unitPrice × quantity (calculé)
}
```

### `BusinessProfile` (SharedPreferences)
```dart
BusinessProfile {
  businessName: String   // Nom du business (obligatoire)
  address: String        // Adresse (obligatoire)
  slogan: String?        // Slogan (facultatif)
  signaturePath: String? // Chemin local vers signature.png
  logoPath: String?      // Chemin local vers logo.png
}
```

**Stockage :**
- Les devis sont stockés dans **SQLite** (`devivy.db`) via `sqflite`
- Le profil est stocké dans **SharedPreferences** (clés préfixées `profile_`)
- L'état app (token JWT, devise, premium) est dans **SharedPreferences** (préfixe `app_`)
- La signature (`signature.png`) et le logo (`logo.png`) sont dans `getApplicationDocumentsDirectory()`

---

## État global (Riverpod)

| Provider | Type | Rôle |
|---|---|---|
| `appStateProvider` | `StateNotifierProvider<AppStateNotifier, AppState>` | Auth, premium, devise, onboarding |
| `quotesProvider` | `AsyncNotifierProvider<QuotesNotifier, List<Quote>>` | Liste des devis + CRUD |
| `profileProvider` | `AsyncNotifierProvider<ProfileNotifier, BusinessProfile>` | Profil établissement |
| `quoteRepositoryProvider` | `Provider<QuoteRepository>` | Accès direct à la DB |
| `profileRepositoryProvider` | `Provider<ProfileRepository>` | Accès direct aux prefs |
| `routerProvider` | `Provider<GoRouter>` | Router réactif à `isOnboarded` |

### `AppState`
```dart
AppState {
  isOnboarded: bool    // Onboarding complété ?
  isPremium: bool      // Compte Premium actif ?
  userEmail: String?   // Email connecté
  authToken: String?   // JWT bearer token
  currency: String     // 'EUR' | 'FCFA' | 'USD' | 'CNY'
}
```

---

## Génération PDF & templates

Le service `lib/services/pdf_service.dart` génère des PDFs via le package `pdf` et les expose via `printing` (aperçu) et `share_plus` (partage/téléchargement).

### API principale

```dart
// Générer un PDF
final bytes = await PdfService.generate(
  quote: quote,
  profile: profile,
  templateId: 'sobre',   // voir catalogue ci-dessous
  currency: 'EUR',
);

// Sauvegarder en temp et partager
final file = await PdfService.saveToTemp(bytes, quote.subject);
await Share.shareXFiles([XFile(file.path)]);
```

### Catalogue des 11 templates

| ID | Nom | Type | Trait distinctif |
|---|---|---|---|
| `sobre` | Sobre | Gratuit | En-tête centré, filet beige-vert |
| `artisan` | Artisan | Gratuit | Noir/blanc, "Bon pour accord" |
| `epure` | Épuré | Gratuit | Minimalisme, total en 20pt |
| `classique` | Classique | Gratuit | Double signature, double filet |
| `compact` | Compact | Gratuit | Police 8pt, marges réduites |
| `service` | Service | Gratuit | Bandeau objet, total arrondi vert |
| `numerote` | Numéroté | Gratuit | Colonne N°, header noir |
| `bandeau` | Bandeau | **Premium** | Bande verte pleine largeur |
| `elegance` | Élégance | **Premium** | Serif, petites capitales |
| `deux_tons` | Deux tons | **Premium** | Colonne latérale verte |
| `resume_tete` | Résumé en tête | **Premium** | Total en 24pt avant le tableau |

### Pagination
Les tableaux utilisent `pw.TableHelper.fromTextArray` (API native du package `pdf`) pour une pagination automatique sur plusieurs pages.

### Polices
- **DM Sans** Regular + Bold chargée depuis `packages/google_fonts/fonts/` via `rootBundle`
- **Lora** Regular + Bold pour le template "Élégance"
- Fallback : Helvetica / Times (polices PDF intégrées) si les assets sont absents

### Signature & logo
Le service relit toujours les fichiers depuis le disque (bypass du cache provider) pour garantir que la signature/logo la plus récente est utilisée :
```dart
final freshSig = await PdfService._freshPath('signature.png');
final freshLogo = await PdfService._freshPath('logo.png');
```

---

## Connexion au backend FastAPI

Le client HTTP est dans `lib/services/api_service.dart`.

### URL de base
```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

| Environnement | URL à utiliser |
|---|---|
| Émulateur Android | `http://10.0.2.2:8000` |
| Appareil physique (même réseau) | `http://192.168.x.x:8000` |
| Production | `https://api.votre-domaine.com` |

### Endpoints utilisés

| Méthode | Route | Fonction Flutter |
|---|---|---|
| `POST` | `/auth/register` | `ApiService.register()` |
| `POST` | `/auth/login` | `ApiService.login()` |
| `POST` | `/premium/purchase` | `ApiService.purchasePremium()` |
| `POST` | `/quotes/sync` | `ApiService.syncQuote()` |
| `GET` | `/quotes` | `ApiService.fetchRemoteQuotes()` |
| `GET` | `/templates` | `ApiService.checkTemplates()` |

Tous les appels authentifiés transmettent le JWT via header `Authorization: Bearer <token>`.

---

## Charte graphique

### Palette (spec §9.1)

| Rôle | Couleur | Hex | Constante Dart |
|---|---|---|---|
| Fond principal | Blanc cassé | `#FDFDFB` | `AppColors.background` |
| Fond secondaire / cartes | Beige-vert | `#E8EACC` | `AppColors.surface` |
| Accent / boutons | Vert sauge | `#8C9C7C` | `AppColors.primary` |
| Texte principal | Anthracite | `#232826` | `AppColors.textDark` |
| Texte fort | Noir profond | `#131114` | `AppColors.textDeep` |
| Séparateurs | Beige-vert clair | `#DDE0C8` | `AppColors.divider` |
| Erreur | Rouge doux | `#B85C5C` | `AppColors.error` |

### Police
**DM Sans** (Google Fonts) — humaniste sans-serif, libre de droits. Utilisée via `GoogleFonts.dmSansTextTheme()` dans le thème global.

### Principes
- Fond d'écran `#FDFDFB` (jamais blanc pur)
- Coins arrondis doux (`BorderRadius.circular(14-16)`) sur cartes et boutons
- Ombres très légères (`BoxShadow` avec `blurRadius: 8, opacity: ~8%`)
- Material 3 (`useMaterial3: true`)

---

## Comportement offline / online

| Action | Hors ligne | En ligne (connecté) |
|---|---|---|
| Créer / modifier / supprimer un devis | ✅ | ✅ |
| Générer un PDF | ✅ | ✅ |
| Imprimer / Partager | ✅ | ✅ |
| Sélectionner un template | ✅ (locaux) | ✅ |
| Synchronisation cloud | ❌ | ✅ |
| Acheter Premium | ❌ | ✅ |
| Vérifier nouveaux templates | ❌ | ✅ silencieux |

---

## Modèle économique côté app

### Mode gratuit
- Quota : **5 devis** maximum (constante `kFreeQuotaLimit = 5` dans `quote_provider.dart`)
- Publicité : à intégrer via `google_mobile_ads` (non encore implémenté, voir `PUBLICITE_ADMOB.md`)
- Templates premium inaccessibles

### Mode Premium
- Débloqué après achat validé par le backend (Stripe)
- Statut stocké dans `SharedPreferences` (`app_premium = true`)
- Devis illimités + tous les templates + sans pub
- Persistant entre les sessions sans rechecking serveur (à valider côté serveur au login)

---

## Configuration Android

### `AndroidManifest.xml`
Permissions déclarées :
- `READ_MEDIA_IMAGES` (Android 13+) — sélection du logo
- `READ_EXTERNAL_STORAGE` (Android ≤12) — sélection du logo
- `WRITE_EXTERNAL_STORAGE` (Android ≤28) — sauvegarde PDF

`FileProvider` déclaré pour `share_plus` (partage de fichiers PDF via Intent Android).

### `build.gradle.kts`
```kotlin
minSdk = 21          // Android 5.0 minimum (requis par sqflite, printing, share_plus)
compileSdk = flutter.compileSdkVersion
```

---

## Points connus / TODO

| Priorité | Élément | Statut |
|---|---|---|
| 🔴 Haute | Intégration AdMob (publicités mode gratuit) | À faire — voir `PUBLICITE_ADMOB.md` |
| 🔴 Haute | Synchronisation cloud complète (push/pull devis) | Client prêt, à brancher UI |
| 🟡 Moyenne | Confirmation achat Premium côté client (Stripe SDK Flutter) | Endpoint backend prêt |
| 🟡 Moyenne | Tests unitaires (repositories, pdf_service) | Non implémentés |
| 🟢 Basse | Numérotation automatique des devis | Non implémenté |
| 🟢 Basse | Export multi-formats (Word, image) | Non implémenté |
| 🟢 Basse | Thème sombre | Non implémenté |
| 🟢 Basse | Build desktop (Flutter Windows/macOS) | Prévu en phase 4 |
