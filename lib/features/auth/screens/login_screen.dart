import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (cred.user != null && mounted) {
        await ref.read(appStateProvider.notifier).onFirebaseLogin(cred.user!);
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      _showError(_msg(e.code));
    } catch (_) {
      _showError('Erreur inattendue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final cred = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
      if (cred.user != null && mounted) {
        await ref.read(appStateProvider.notifier).onFirebaseLogin(cred.user!);
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      _showError(_msg(e.code));
    } catch (_) {
      _showError('Connexion Google impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );

  String _msg(String code) => switch (code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Email ou mot de passe incorrect.',
        'user-disabled' => 'Ce compte est désactivé.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        'network-request-failed' => 'Pas de connexion internet.',
        _ => 'Erreur de connexion ($code).',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline,
                    size: 32, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text('Connexion',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Optionnel — utile pour sauvegarder vos devis dans le cloud ou passer en Premium.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withAlpha(160), height: 1.4),
            ),
            const SizedBox(height: 28),

            // Bouton Google
            GoogleSignInButton(
              loading: _googleLoading,
              onTap: (_loading || _googleLoading) ? null : _loginGoogle,
            ),
            const SizedBox(height: 16),
            const AuthSeparator(),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                  return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      color: AppColors.primary),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loginEmail(),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_loading || _googleLoading) ? null : _loginEmail,
              child: _loading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white))
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Pas encore de compte ? ',
                  style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: () => context.pushReplacement('/register'),
                child: const Text('Créer un compte',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

