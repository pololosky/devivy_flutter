import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool isOnboarded;
  final bool isPremium;
  final String? userEmail;
  final String? authToken;
  final String currency; // e.g. 'EUR', 'FCFA', 'USD', 'CNY'

  const AppState({
    this.isOnboarded = false,
    this.isPremium = false,
    this.userEmail,
    this.authToken,
    this.currency = 'EUR',
  });

  bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;

  AppState copyWith({
    bool? isOnboarded,
    bool? isPremium,
    String? userEmail,
    String? authToken,
    String? currency,
    bool clearToken = false,
  }) =>
      AppState(
        isOnboarded: isOnboarded ?? this.isOnboarded,
        isPremium: isPremium ?? this.isPremium,
        userEmail: userEmail ?? this.userEmail,
        authToken: clearToken ? null : (authToken ?? this.authToken),
        currency: currency ?? this.currency,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isOnboarded: prefs.getBool('app_onboarded') ?? false,
      isPremium: prefs.getBool('app_premium') ?? false,
      userEmail: prefs.getString('app_user_email'),
      authToken: prefs.getString('app_auth_token'),
      currency: prefs.getString('app_currency') ?? 'EUR',
    );
  }

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

  Future<void> setLoggedIn({
    required String email,
    required String token,
    required bool isPremium,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_user_email', email);
    await prefs.setString('app_auth_token', token);
    await prefs.setBool('app_premium', isPremium);
    state = state.copyWith(
      userEmail: email,
      authToken: token,
      isPremium: isPremium,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_user_email');
    await prefs.remove('app_auth_token');
    state = state.copyWith(clearToken: true, userEmail: '');
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_premium', value);
    state = state.copyWith(isPremium: value);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
