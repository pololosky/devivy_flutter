import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
        'email-already-in-use' => 'Cet email est déjà utilisé.',
        'weak-password' => 'Mot de passe trop court (6 caractères minimum).',
        'invalid-email' => 'Email invalide.',
        'network-request-failed' => 'Pas de connexion internet.',
        _ => 'Erreur ($code). Réessayez.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
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
            Text('Créer un compte',
                style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 6),
            Text(
              'Facultatif — nécessaire uniquement pour la sync cloud et le Premium.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withAlpha(160), height: 1.4),
            ),
            const SizedBox(height: 24),

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
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                if (v.length < 6) return '6 caractères minimum';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: (v) => v != _passCtrl.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_loading || _googleLoading) ? null : _register,
              child: _loading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white))
                  : const Text('Créer mon compte'),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Déjà un compte ? ',
                  style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: () => context.pushReplacement('/login'),
                child: const Text('Se connecter',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
