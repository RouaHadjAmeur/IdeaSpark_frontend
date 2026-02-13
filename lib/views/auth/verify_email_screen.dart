import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/auth_view_model.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.isGoogleVerification = false,
    this.isFacebookVerification = false,
  });

  final String email;
  final bool isGoogleVerification;
  final bool isFacebookVerification;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();
    bool success = false;
    if (widget.isGoogleVerification) {
      success = await vm.verifyGoogleWithCode(_codeController.text);
    } else if (widget.isFacebookVerification) {
      success = await vm.verifyFacebookWithCode(_codeController.text);
    } else {
      success = await vm.verifyEmail(widget.email, _codeController.text);
    }
    if (!context.mounted) return;
    if (success) {
      final userId = vm.userId ?? '';
      context.go('/persona-onboarding', extra: userId);
    }
  }

  Future<void> _resend(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();
    if (widget.isGoogleVerification) {
      await vm.resendGoogleCode();
    } else if (widget.isFacebookVerification) {
      await vm.resendFacebookCode();
    } else {
      await vm.resendVerificationCode(widget.email);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('verify_email_sent'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthViewModel>(
            builder: (context, vm, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    context.tr('verify_email_title'),
                    style: GoogleFonts.syne(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.tr('verify_email_sent')} ${widget.email}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (vm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: context.tr('verify_code_hint'),
                      hintText: '123456',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verify(context),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: vm.isLoading ? null : () => _verify(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('verify_button')),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: vm.isLoading ? null : () => _resend(context),
                    child: Text(context.tr('resend_code')),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(context.tr('login')),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
