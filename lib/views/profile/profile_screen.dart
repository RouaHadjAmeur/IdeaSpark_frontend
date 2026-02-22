import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/profile_view_model.dart';
import 'package:ideaspark/view_models/theme_view_model.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';
import 'package:ideaspark/models/persona_model.dart';

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
                title: Text(ctx.tr('french')),
                trailing: localeVm.locale == 'fr' ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
                onTap: () async {
                  await localeVm.setLocale('fr');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: Text(ctx.tr('english')),
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
                _PersonaSection(vm: vm, colorScheme: colorScheme),
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

class _PersonaSection extends StatelessWidget {
  final ProfileViewModel vm;
  final ColorScheme colorScheme;

  const _PersonaSection({required this.vm, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('persona_section_title'),
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: vm.isPersonaLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          context.tr('persona_loading'),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : vm.hasPersona
                      ? _PersonaDetails(persona: vm.persona!, colorScheme: colorScheme, vm: vm)
                      : _PersonaEmpty(colorScheme: colorScheme),
            ),
            if (vm.isPersonaUpdating)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (vm.hasPersona) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final userId = vm.persona?.userId ?? '';
                await context.push('/persona-onboarding?userId=$userId');
                if (context.mounted) {
                  vm.refreshPersona();
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                context.tr('persona_retake_quiz'),
                style: const TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        if (!vm.hasPersona && !vm.isPersonaLoading) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.push('/persona-onboarding');
                if (context.mounted) {
                  vm.refreshPersona();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.tr('persona_setup_button')),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonaEmpty extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PersonaEmpty({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('persona_not_configured'),
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PersonaDetails extends StatelessWidget {
  final PersonaModel persona;
  final ColorScheme colorScheme;
  final ProfileViewModel vm;

  const _PersonaDetails({
    required this.persona,
    required this.colorScheme,
    required this.vm,
  });

  // Bilingual mappings for string-based fields
  static const Map<String, String> _nicheEn = {
    'Business': 'Business', 'E-commerce': 'E-commerce', 'Beauté': 'Beauty',
    'Fitness': 'Fitness', 'Tech': 'Tech', 'Lifestyle': 'Lifestyle',
    'Éducation': 'Education', 'Autre': 'Other',
  };
  static const List<String> _nicheOptionsFr = [
    'Business', 'E-commerce', 'Beauté', 'Fitness', 'Tech', 'Lifestyle', 'Éducation', 'Autre',
  ];

  static const Map<String, String> _audienceEn = {
    'Étudiants': 'Students', 'Jeunes actifs': 'Young professionals',
    'Femmes': 'Women', 'Hommes': 'Men', 'Entrepreneurs': 'Entrepreneurs',
    'Mixte': 'Mixed',
  };
  static const List<String> _audienceOptionsFr = [
    'Étudiants', 'Jeunes actifs', 'Femmes', 'Hommes', 'Entrepreneurs', 'Mixte',
  ];

  static const Map<String, String> _ctaEn = {
    'Abonne-toi': 'Subscribe', 'Commente': 'Comment', 'Lien en bio': 'Link in bio',
    'DM': 'DM', 'WhatsApp': 'WhatsApp', 'Commander': 'Order',
  };
  static const List<String> _ctaOptionsFr = [
    'Abonne-toi', 'Commente', 'Lien en bio', 'DM', 'WhatsApp', 'Commander',
  ];

  static const Map<String, String> _langDisplay = {
    'fr': 'Français', 'ar': 'Arabe', 'en': 'English', 'mix': 'Mixte',
  };
  static const Map<String, String> _langDisplayEn = {
    'fr': 'French', 'ar': 'Arabic', 'en': 'English', 'mix': 'Mixed',
  };
  static const List<String> _langCodes = ['fr', 'ar', 'en', 'mix'];

  static const Map<String, String> _mainPlatformLabels = {
    'tiktok': 'TikTok', 'instagram': 'Instagram', 'youtube': 'YouTube', 'facebook': 'Facebook',
  };
  static const List<String> _mainPlatformCodes = ['tiktok', 'instagram', 'youtube', 'facebook'];

  static const Map<String, String> _freqPlatformLabels = {
    'tiktok': 'TikTok', 'instagram reels': 'Instagram Reels',
    'instagram stories': 'Instagram Stories', 'youtube shorts': 'YouTube Shorts',
    'youtube long': 'YouTube Long', 'facebook': 'Facebook',
  };
  static const List<String> _freqPlatformCodes = [
    'tiktok', 'instagram reels', 'instagram stories', 'youtube shorts', 'youtube long', 'facebook',
  ];

  List<String> _localize(List<String> values, Map<String, String> enMap, String locale) {
    if (locale != 'en') return values;
    return values.map((v) => enMap[v] ?? v).toList();
  }

  String _localizeOne(String value, Map<String, String> enMap, String locale) {
    if (locale != 'en') return value;
    return enMap[value] ?? value;
  }

  // ── Multi-select dialog ──
  void _showMultiSelectDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required List<T> current,
    required String Function(T) labelBuilder,
    required void Function(List<T>) onConfirmed,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _MultiSelectDialog<T>(
        title: title,
        options: options,
        initialSelected: current,
        labelBuilder: labelBuilder,
        onConfirmed: (values) {
          Navigator.of(ctx).pop();
          onConfirmed(values);
        },
        tr: context.tr,
      ),
    );
  }

  Future<void> _updateField(BuildContext context, PersonaModel updated) async {
    final ok = await vm.updatePersonaField(updated);
    if (!context.mounted) return;
    final cs = Theme.of(context).colorScheme;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('persona_update_success')),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (vm.personaUpdateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.personaUpdateError!),
          backgroundColor: cs.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    final langLabel = locale == 'en'
        ? (_langDisplayEn[persona.language] ?? persona.language)
        : (_langDisplay[persona.language] ?? persona.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile type (dropdown)
        _PersonaDropdownRow<ProfileType>(
          label: context.tr('persona_profile_label'),
          displayValue: persona.profile.localizedLabel(locale),
          colorScheme: colorScheme,
          options: ProfileType.values,
          currentValue: persona.profile,
          labelBuilder: (e) => e.localizedLabel(locale),
          onChanged: (v) => _updateField(context, persona.copyWith(profile: v)),
        ),
        // Goal (dropdown)
        _PersonaDropdownRow<ContentGoal>(
          label: context.tr('persona_goal_label'),
          displayValue: persona.goal.localizedLabel(locale),
          colorScheme: colorScheme,
          options: ContentGoal.values,
          currentValue: persona.goal,
          labelBuilder: (e) => e.localizedLabel(locale),
          onChanged: (v) => _updateField(context, persona.copyWith(goal: v)),
        ),
        // Niches (multi-select dialog)
        _PersonaChipsRow(
          label: context.tr('persona_niches_label'),
          values: _localize(persona.niches, _nicheEn, locale),
          colorScheme: colorScheme,
          onTap: () => _showMultiSelectDialog<String>(
            context: context,
            title: context.tr('persona_niches_label'),
            options: _nicheOptionsFr,
            current: persona.niches,
            labelBuilder: (v) => _localizeOne(v, _nicheEn, locale),
            onConfirmed: (v) => _updateField(context, persona.copyWith(niches: v)),
          ),
        ),
        // Main platform (dropdown)
        _PersonaDropdownRow<String>(
          label: context.tr('persona_platform_label'),
          displayValue: _mainPlatformLabels[persona.mainPlatform] ?? persona.mainPlatform,
          colorScheme: colorScheme,
          options: _mainPlatformCodes,
          currentValue: persona.mainPlatform,
          labelBuilder: (v) => _mainPlatformLabels[v] ?? v,
          onChanged: (v) => _updateField(context, persona.copyWith(mainPlatform: v)),
        ),
        // Frequent platforms (multi-select dialog)
        _PersonaChipsRow(
          label: context.tr('persona_platforms_label'),
          values: persona.platforms.map((p) => _freqPlatformLabels[p] ?? p).toList(),
          colorScheme: colorScheme,
          onTap: () => _showMultiSelectDialog<String>(
            context: context,
            title: context.tr('persona_platforms_label'),
            options: _freqPlatformCodes,
            current: persona.platforms,
            labelBuilder: (v) => _freqPlatformLabels[v] ?? v,
            onConfirmed: (v) => _updateField(context, persona.copyWith(platforms: v)),
          ),
        ),
        // Content styles (multi-select dialog)
        _PersonaChipsRow(
          label: context.tr('persona_styles_label'),
          values: persona.contentStyles.map((s) => s.localizedLabel(locale)).toList(),
          colorScheme: colorScheme,
          onTap: () => _showMultiSelectDialog<ContentStyle>(
            context: context,
            title: context.tr('persona_styles_label'),
            options: ContentStyle.values,
            current: persona.contentStyles,
            labelBuilder: (e) => e.localizedLabel(locale),
            onConfirmed: (v) => _updateField(context, persona.copyWith(contentStyles: v)),
          ),
        ),
        // Tone (dropdown)
        _PersonaDropdownRow<ContentTone>(
          label: context.tr('persona_tone_label'),
          displayValue: persona.tone.localizedLabel(locale),
          colorScheme: colorScheme,
          options: ContentTone.values,
          currentValue: persona.tone,
          labelBuilder: (e) => e.localizedLabel(locale),
          onChanged: (v) => _updateField(context, persona.copyWith(tone: v)),
        ),
        // Audiences (multi-select dialog)
        _PersonaChipsRow(
          label: context.tr('persona_audiences_label'),
          values: _localize(persona.audiences, _audienceEn, locale),
          colorScheme: colorScheme,
          onTap: () => _showMultiSelectDialog<String>(
            context: context,
            title: context.tr('persona_audiences_label'),
            options: _audienceOptionsFr,
            current: persona.audiences,
            labelBuilder: (v) => _localizeOne(v, _audienceEn, locale),
            onConfirmed: (v) => _updateField(context, persona.copyWith(audiences: v)),
          ),
        ),
        // Audience age (dropdown)
        _PersonaDropdownRow<AudienceAge>(
          label: context.tr('persona_age_label'),
          displayValue: persona.audienceAge.localizedLabel(locale),
          colorScheme: colorScheme,
          options: AudienceAge.values,
          currentValue: persona.audienceAge,
          labelBuilder: (e) => e.localizedLabel(locale),
          onChanged: (v) => _updateField(context, persona.copyWith(audienceAge: v)),
        ),
        // Language (dropdown)
        _PersonaDropdownRow<String>(
          label: context.tr('persona_lang_label'),
          displayValue: langLabel,
          colorScheme: colorScheme,
          options: _langCodes,
          currentValue: persona.language,
          labelBuilder: (v) => locale == 'en'
              ? (_langDisplayEn[v] ?? v)
              : (_langDisplay[v] ?? v),
          onChanged: (v) => _updateField(context, persona.copyWith(language: v)),
        ),
        // CTAs (multi-select dialog)
        _PersonaChipsRow(
          label: context.tr('persona_ctas_label'),
          values: _localize(persona.ctas, _ctaEn, locale),
          colorScheme: colorScheme,
          isLast: true,
          onTap: () => _showMultiSelectDialog<String>(
            context: context,
            title: context.tr('persona_ctas_label'),
            options: _ctaOptionsFr,
            current: persona.ctas,
            labelBuilder: (v) => _localizeOne(v, _ctaEn, locale),
            onConfirmed: (v) => _updateField(context, persona.copyWith(ctas: v)),
          ),
        ),
      ],
    );
  }
}

/// Dropdown row for single-select persona fields using PopupMenuButton.
class _PersonaDropdownRow<T> extends StatelessWidget {
  final String label;
  final String displayValue;
  final ColorScheme colorScheme;
  final List<T> options;
  final T currentValue;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _PersonaDropdownRow({
    super.key,
    required this.label,
    required this.displayValue,
    required this.colorScheme,
    required this.options,
    required this.currentValue,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PopupMenuButton<T>(
        onSelected: (value) {
          if (value != currentValue) onChanged(value);
        },
        initialValue: currentValue,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surfaceContainerHighest,
        itemBuilder: (ctx) => options.map((opt) {
          final isSelected = opt == currentValue;
          return PopupMenuItem<T>(
            value: opt,
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelBuilder(opt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for multi-select persona fields with checkboxes.
class _MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final List<T> initialSelected;
  final String Function(T) labelBuilder;
  final void Function(List<T>) onConfirmed;
  final String Function(String) tr;

  const _MultiSelectDialog({
    super.key,
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.labelBuilder,
    required this.onConfirmed,
    required this.tr,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.initialSelected);
  }

  void _toggle(T item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: GoogleFonts.syne(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.options.length,
          itemBuilder: (ctx, i) {
            final opt = widget.options[i];
            final isSelected = _selected.contains(opt);
            return ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text(
                widget.labelBuilder(opt),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              trailing: Icon(
                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 22,
              ),
              onTap: () => _toggle(opt),
            );
          },
        ),
      ),
      actions: [
        if (_selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              widget.tr('persona_min_one_required'),
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: _selected.isNotEmpty
              ? () => widget.onConfirmed(_selected)
              : null,
          child: Text(widget.tr('persona_confirm_selection')),
        ),
      ],
    );
  }
}

/// Chips row for multi-select persona fields - tapping opens a dialog.
class _PersonaChipsRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final ColorScheme colorScheme;
  final bool isLast;
  final VoidCallback? onTap;

  const _PersonaChipsRow({
    required this.label,
    required this.values,
    required this.colorScheme,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: values.map((v) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_drop_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
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
