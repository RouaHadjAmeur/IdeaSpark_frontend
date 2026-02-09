import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/profile_view_model.dart';
import 'package:ideaspark/view_models/theme_view_model.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';

void _showDeleteAccountFlow(BuildContext context, ProfileViewModel vm) {
  final colorScheme = Theme.of(context).colorScheme;
  final tr = context.tr;

  // Step 1: Confirm and request code
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr('delete_account_confirm_title')),
      content: Text(tr('delete_account_confirm_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: vm.isDeleteLoading
              ? null
              : () async {
                  Navigator.of(dialogContext).pop();
                  final ok = await vm.requestDeleteAccountCode();
                  if (!context.mounted) return;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('delete_account_code_sent'))),
                    );
                    _showDeleteAccountCodeDialog(context, vm);
                  } else if (vm.deleteErrorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.deleteErrorMessage!),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                },
          child: vm.isDeleteLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr('delete_account_send_code')),
        ),
      ],
    ),
  );
}

void _showDeleteAccountCodeDialog(BuildContext context, ProfileViewModel vm) {
  final colorScheme = Theme.of(context).colorScheme;
  final tr = context.tr;
  final userEmail = vm.email;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DeleteAccountCodeDialog(
      colorScheme: colorScheme,
      userEmail: userEmail,
      vm: vm,
      tr: tr,
      onSuccess: () {
        Navigator.of(dialogContext).pop();
        context.go('/login');
      },
      onCancel: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _DeleteAccountCodeDialog extends StatefulWidget {
  const _DeleteAccountCodeDialog({
    required this.colorScheme,
    required this.userEmail,
    required this.vm,
    required this.tr,
    required this.onSuccess,
    required this.onCancel,
  });

  final ColorScheme colorScheme;
  final String userEmail;
  final ProfileViewModel vm;
  final String Function(String) tr;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  State<_DeleteAccountCodeDialog> createState() => _DeleteAccountCodeDialogState();
}

class _DeleteAccountCodeDialogState extends State<_DeleteAccountCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        return AlertDialog(
          title: Text(widget.tr('delete_account_enter_code_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.tr('delete_account_enter_code_message')} ${widget.userEmail}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.vm.deleteErrorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.vm.deleteErrorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: widget.tr('verify_code_hint'),
                  hintText: '123456',
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: widget.vm.isDeleteLoading ? null : widget.onCancel,
              child: Text(widget.tr('cancel')),
            ),
            FilledButton(
              onPressed: widget.vm.isDeleteLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: widget.colorScheme.error,
              ),
              child: widget.vm.isDeleteLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.tr('delete_account_confirm_button')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    widget.vm.clearDeleteError();
    final ok = await widget.vm.confirmDeleteAccount(_codeController.text);
    if (!mounted) return;
    if (ok) widget.onSuccess();
  }
}

void _showChangePasswordDialog(BuildContext context, ProfileViewModel vm) {
  final colorScheme = Theme.of(context).colorScheme;
  final tr = context.tr;
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => ListenableBuilder(
      listenable: vm,
      builder: (_, __) {
        return AlertDialog(
          title: Text(tr('change_password_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('current_password'),
                    hintText: tr('password_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('new_password'),
                    hintText: tr('password_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('confirm_password'),
                    hintText: tr('password_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (vm.changePasswordErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vm.changePasswordErrorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: vm.isChangePasswordLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: vm.isChangePasswordLoading
                  ? null
                  : () async {
                      vm.clearChangePasswordError();
                      final newP = newController.text;
                      final confirm = confirmController.text;
                      if (newP != confirm) {
                        vm.clearChangePasswordError();
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(tr('passwords_do_not_match')),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                        return;
                      }
                      final ok = await vm.changePassword(currentController.text, newP);
                      if (!dialogContext.mounted) return;
                      if (ok) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('change_password_success'))),
                        );
                      }
                    },
              child: vm.isChangePasswordLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr('change_password_confirm')),
            ),
          ],
        );
      },
    ),
  );
}

void _showLanguageSheet(BuildContext context, ColorScheme colorScheme) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colorScheme.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final localeVm = ctx.read<LocaleViewModel>();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ctx.tr('language_label'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Français'),
                trailing: localeVm.locale == 'fr' ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
                onTap: () async {
                  await localeVm.setLocale('fr');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: localeVm.locale == 'en' ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
                onTap: () async {
                  await localeVm.setLocale('en');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: vm.profilePicture == null
                        ? LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                          )
                        : null,
                    shape: BoxShape.circle,
                    image: vm.profilePicture != null
                        ? DecorationImage(
                            image: vm.profilePicture!.startsWith('data:')
                                ? MemoryImage(base64Decode(vm.profilePicture!.split(',').last))
                                : NetworkImage(vm.profilePicture!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: vm.profilePicture == null
                      ? const Center(
                          child: Text('👤', style: TextStyle(fontSize: 32)),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  vm.displayName,
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _SettingsGroup(
                  title: context.tr('preferences'),
                  colorScheme: colorScheme,
                  children: [
                    _SettingRow(
                      label: context.tr('dark_mode'),
                      colorScheme: colorScheme,
                      trailing: Switch(
                        value: themeVm.isDarkMode,
                        onChanged: themeVm.setDarkMode,
                        activeTrackColor: colorScheme.primary,
                      ),
                    ),
                    _SettingRow(
                      label: context.tr('daily_reminder'),
                      colorScheme: colorScheme,
                      trailing: Switch(
                        value: vm.dailyReminder,
                        onChanged: vm.setDailyReminder,
                        activeTrackColor: colorScheme.primary,
                      ),
                    ),
                    _SettingRow(
                      label: context.tr('language_label'),
                      colorScheme: colorScheme,
                      trailing: Consumer<LocaleViewModel>(
                        builder: (context, localeVm, _) => Text(
                          localeVm.locale == 'en' ? '${context.tr('english')} →' : '${context.tr('french')} →',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      onTap: () => _showLanguageSheet(context, colorScheme),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: context.tr('content'),
                  colorScheme: colorScheme,
                  children: [
                    _SettingRow(
                      label: context.tr('export_ideas'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.description_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () {},
                    ),
                    _SettingRow(
                      label: context.tr('full_history'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.history_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: context.tr('support'),
                  colorScheme: colorScheme,
                  children: [
                    _SettingRow(
                      label: context.tr('rate_app'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.star_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () {},
                    ),
                    _SettingRow(
                      label: context.tr('feedback'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.feedback_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: Icon(
                    Icons.credit_card_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    context.tr('credits_shop_profile'),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => context.push('/credits-shop'),
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: context.tr('account'),
                  colorScheme: colorScheme,
                  children: [
                    _SettingRow(
                      label: context.tr('personal_information'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.person_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () async {
                        await context.push('/edit-profile');
                        if (context.mounted) {
                          vm.refresh();
                        }
                      },
                    ),
                    _SettingRow(
                      label: context.tr('change_password'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.lock_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () => _showChangePasswordDialog(context, vm),
                    ),
                    _SettingRow(
                      label: context.tr('delete_account'),
                      colorScheme: colorScheme,
                      trailing: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                        size: 22,
                      ),
                      onTap: () => _showDeleteAccountFlow(context, vm),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await vm.signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(context.tr('sign_out')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.label,
    required this.colorScheme,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
