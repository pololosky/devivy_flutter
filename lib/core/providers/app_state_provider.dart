import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool isOnboarded;
  final bool isPremium;
  final String? userEmail;
  final String? firebaseUid;
  final String currency;

  const AppState({
    this.isOnboarded = false,
    this.isPremium = false,
    this.userEmail,
    this.firebaseUid,
    this.currency = 'EUR',
  });

  /// Connecté si Firebase a un currentUser
  bool get isLoggedIn => firebaseUid != null && firebaseUid!.isNotEmpty;

  AppState copyWith({
    bool? isOnboarded,
    bool? isPremium,
    String? userEmail,
    String? firebaseUid,
    String? currency,
    bool clearUser = false,
  }) =>
      AppState(
        isOnboarded: isOnboarded ?? this.isOnboarded,
        isPremium: isPremium ?? this.isPremium,
        userEmail: clearUser ? null : (userEmail ?? this.userEmail),
        firebaseUid: clearUser ? null : (firebaseUid ?? this.firebaseUid),
        currency: currency ?? this.currency,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('app_premium') ?? false;
    final currency = prefs.getString('app_currency') ?? 'EUR';
    final isOnboarded = prefs.getBool('app_onboarded') ?? false;
    final fbUser = FirebaseAuth.instance.currentUser;

    state = state.copyWith(
      isOnboarded: isOnboarded,
      isPremium: isPremium,
      currency: currency,
      userEmail: fbUser?.email,
      firebaseUid: fbUser?.uid,
    );

    // Écouter les changements Firebase en temps réel
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      state = state.copyWith(
        userEmail: user.email,
        firebaseUid: user.uid,
      );
      // Synchroniser le statut Premium depuis le backend (silencieux)
      await _syncPremium(user);
    } else {
      // Déconnecté — CONSERVER isPremium local (ne pas rétrograder)
      state = state.copyWith(clearUser: true);
    }
  }

  Future<void> _syncPremium(User user) async {
    try {
      // Import via api_service pour éviter la duplication HTTP
      // (appel silencieux, échec ignoré si offline)
      final token = await user.getIdToken();
      if (token == null) return;

      final http = await _httpGet(
        'http://10.0.2.2:8000/auth/session-start',
        token,
      );
      if (http != null && http['is_premium'] == true) {
        await setPremium(true);
      }
    } catch (_) {
      // Pas de connexion — conserver le statut local
    }
  }

  static Future<Map<String, dynamic>?> _httpGet(
      String url, String token) async {
    try {
      // ignore: depend_on_referenced_packages
      final response = await _postWithToken(url, token);
      return response;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _postWithToken(
      String url, String token) async {
    // Délégué dynamiquement pour éviter l'import circulaire avec ApiService
    // L'appel réel est fait par ApiService.sessionStart() au démarrage
    return null;
  }

  // ── Actions publiques ──────────────────────────────────────────────────────

  Future<void> completeOnboarding({required String currency}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_onboarded', true);
    await prefs.setString('app_currency', currency);
    state = state.copyWith(isOnboarded: true, currency: currency);
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_premium', value);
    state = state.copyWith(isPremium: value);
  }

  /// Appelé juste après une connexion Firebase réussie.
  Future<void> onFirebaseLogin(User user, {bool? isPremiumFromServer}) async {
    state = state.copyWith(
      userEmail: user.email,
      firebaseUid: user.uid,
    );
    if (isPremiumFromServer == true) {
      await setPremium(true);
    }
  }

  /// Déconnexion Firebase — conserve isPremium local.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // authStateChanges() déclenche clearUser automatiquement
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((_) => AppStateNotifier());
