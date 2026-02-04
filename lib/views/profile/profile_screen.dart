import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/profile_view_model.dart';
import 'package:ideaspark/view_models/theme_view_model.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';

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
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 32)),
                  ),
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
