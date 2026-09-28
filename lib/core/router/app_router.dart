import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/quotes/screens/quotes_list_screen.dart';
import '../../features/quotes/screens/quote_form_screen.dart';
import '../../features/quotes/screens/quote_preview_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/profile_edit_screen.dart';
import '../../features/settings/screens/signature_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/settings/screens/legal_screen.dart';
import '../providers/app_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: appState.isOnboarded ? '/quotes' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/quotes',
        name: 'quotes',
        builder: (context, state) => const QuotesListScreen(),
      ),
      GoRoute(
        path: '/quotes/new',
        name: 'quote-new',
        builder: (context, state) => const QuoteFormScreen(),
      ),
      GoRoute(
        path: '/quotes/:id/edit',
        name: 'quote-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuoteFormScreen(quoteId: id);
        },
      ),
      GoRoute(
        path: '/quotes/:id/preview',
        name: 'quote-preview',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuotePreviewScreen(quoteId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile-edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: 'signature',
            name: 'signature',
            builder: (context, state) => const SignatureScreen(),
          ),
          GoRoute(
            path: 'premium',
            name: 'premium',
            builder: (context, state) => const PremiumScreen(),
          ),
          GoRoute(
            path: 'legal/privacy',
            name: 'legal-privacy',
            builder: (context, state) =>
                const LegalScreen(page: LegalPage.privacy),
          ),
          GoRoute(
            path: 'legal/terms',
            name: 'legal-terms',
            builder: (context, state) =>
                const LegalScreen(page: LegalPage.terms),
          ),
          GoRoute(
            path: 'legal/mentions',
            name: 'legal-mentions',
            builder: (context, state) =>
                const LegalScreen(page: LegalPage.mentions),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
});
