import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [BoxShadow(
                color: AppColors.cardShadow, blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: loading
              ? const Center(child: SizedBox(height: 22, width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Center(
                      child: Text('G', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Continuer avec Google',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark)),
                ]),
        ),
      );
}

class AuthSeparator extends StatelessWidget {
  const AuthSeparator({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withAlpha(160))),
        ),
        const Expanded(child: Divider()),
      ]);
}
