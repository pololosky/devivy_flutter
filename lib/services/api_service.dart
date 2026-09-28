import 'dart:convert';
import 'package:http/http.dart' as http;

/// Devivy API client — points to the FastAPI backend.
/// Change [baseUrl] to match your server in production.
class ApiService {
  ApiService._();

  // Update this to your actual server URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static const _headers = {'Content-Type': 'application/json'};

  // ── Auth ────────────────────────────────────────────────────────────────

  /// Returns {token, isPremium} or null on failure.
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'token': data['access_token'] as String,
          'isPremium': (data['is_premium'] as bool?) ?? false,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns {token} or null on failure.
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'token': data['access_token'] as String};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Premium ─────────────────────────────────────────────────────────────

  /// Triggers premium purchase (payment intent via Stripe on backend).
  /// Returns true on success.
  static Future<bool> purchasePremium({required String token}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/premium/purchase'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Sync ────────────────────────────────────────────────────────────────

  /// Push a quote to the backend for cloud sync.
  static Future<String?> syncQuote({
    required String token,
    required Map<String, dynamic> quoteJson,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/quotes/sync'),
            headers: _authHeaders(token),
            body: jsonEncode(quoteJson),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['id'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch all synced quotes from backend.
  static Future<List<Map<String, dynamic>>?> fetchRemoteQuotes({
    required String token,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/quotes'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Templates ───────────────────────────────────────────────────────────

  /// Check for new template versions from the server.
  static Future<List<Map<String, dynamic>>?> checkTemplates({
    required String token,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/templates'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
