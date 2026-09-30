import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Client HTTP Devivy — authentification via Firebase ID Token.
/// Tous les appels sont conditionnés à FirebaseAuth.instance.currentUser != null.
class ApiService {
  ApiService._();

  static const String baseUrl = 'http://10.0.2.2:8000';
  // Pour appareil physique sur le même réseau : 'http://192.168.x.x:8000'
  // Pour production : 'https://api.devivy.app'

  // ── Headers ────────────────────────────────────────────────────────────────

  static Future<Map<String, String>?> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Session start ──────────────────────────────────────────────────────────

  /// Appelé une fois au démarrage si connecté. Synchronise le statut Premium.
  /// Retourne {is_premium: bool} ou null si offline/non connecté.
  static Future<Map<String, dynamic>?> sessionStart() async {
    final headers = await _headers();
    if (headers == null) return null;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/auth/session-start'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Premium ────────────────────────────────────────────────────────────────

  static Future<bool?> getPremiumStatus() async {
    final headers = await _headers();
    if (headers == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/premium/status'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['is_premium'] as bool?;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> confirmPremium() async {
    final headers = await _headers();
    if (headers == null) return false;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/premium/confirm'), headers: headers)
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Sync devis ─────────────────────────────────────────────────────────────

  static Future<String?> syncQuote(Map<String, dynamic> quoteJson) async {
    final headers = await _headers();
    if (headers == null) return null;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/quotes/sync'),
              headers: headers, body: jsonEncode(quoteJson))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>?> fetchRemoteQuotes() async {
    final headers = await _headers();
    if (headers == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/quotes'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> deleteRemoteQuote(String localId) async {
    final headers = await _headers();
    if (headers == null) return;
    try {
      await http
          .delete(Uri.parse('$baseUrl/quotes/$localId'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Templates ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>?> checkTemplates() async {
    final headers = await _headers();
    if (headers == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/templates'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }
}
