import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/auth_view_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();
    final success = await vm.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
    if (!context.mounted) return;
    if (success) {
      context.go('/verify-email', extra: _emailController.text.trim());
    }
  }

  Future<void> _signUpWithGoogle(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();
    final result = await vm.signInWithGoogle();
    if (!context.mounted) return;
    if (result == null) return;
    if (result.loggedIn) {
      context.go('/onboarding');
    } else if (result.requiresVerification && result.emailForVerification != null) {
      context.go('/verify-email', extra: {
        'email': result.emailForVerification!,
        'source': 'google',
      });
    }
  }

  Future<void> _signUpWithFacebook(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();
    final result = await vm.signInWithFacebook();
    if (!context.mounted) return;
    if (result == null) return;
    if (result.loggedIn) {
      context.go('/onboarding');
    } else if (result.requiresVerification && result.emailForVerification != null) {
      context.go('/verify-email', extra: {
        'email': result.emailForVerification!,
        'source': 'facebook',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colorScheme.primary, context.accentColor],
                    ).createShader(bounds),
                    child: Text(
                      context.tr('app_name'),
                      style: GoogleFonts.syne(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('signup'),
                    style: GoogleFonts.syne(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (vm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.errorColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(
                          color: context.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.tr('email'),
                      hintText: context.tr('email_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.tr('password'),
                      hintText: context.tr('password_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.tr('confirm_password'),
                      hintText: context.tr('password_hint'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () => _signUpWithEmail(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.tr('sign_up')),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: colorScheme.onSurfaceVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.tr('or'),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SocialButton(
                    icon: 'G',
                    label: context.tr('signup_google'),
                    colorScheme: colorScheme,
                    onPressed: vm.isLoading
                        ? null
                        : () => _signUpWithGoogle(context),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: 'f',
                    label: context.tr('signup_facebook'),
                    colorScheme: colorScheme,
                    onPressed: vm.isLoading
                        ? null
                        : () => _signUpWithFacebook(context),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('has_account'),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          context.tr('sign_in'),
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
