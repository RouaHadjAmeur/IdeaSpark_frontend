import 'package:flutter/material.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../view_models/persona_onboarding_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../services/persona_service.dart';
import '../../models/persona_model.dart';

/// Persona Onboarding Screen - Matches HTML reference design
class PersonaOnboardingScreen extends StatelessWidget {
  final String userId;

  const PersonaOnboardingScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PersonaOnboardingViewModel(
        personaService: PersonaService(),
        userId: userId,
      ),
      child: const _PersonaOnboardingView(),
    );
  }
}

class _PersonaOnboardingView extends StatelessWidget {
  const _PersonaOnboardingView();

  // Design system colors matching HTML
  static const Color primaryColor = Color(0xFF00D9FF);
  static const Color secondaryColor = Color(0xFFFF3D71);
  static const Color accentColor = Color(0xFFFFD93D);

  // Dark mode colors
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCardDark = Color(0xFF151B2D);
  static const Color bgElevatedDark = Color(0xFF1A2139);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8B95B0);
  static const Color textTertiaryDark = Color(0xFF5A6482);

  // Light mode colors
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgElevatedLight = Color(0xFFF0F2F5);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // Helper method to get colors based on theme
  static Color getBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;
  }

  static Color getBgCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? bgCardDark : bgCardLight;
  }

  static Color getBgElevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? bgElevatedDark : bgElevatedLight;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textTertiaryDark : textTertiaryLight;
  }

  static List<Color> getBgGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [const Color(0xFF0F0C29), const Color(0xFF1A1535), const Color(0xFF24243E)]
        : [const Color(0xFFE0E7FF), const Color(0xFFF5F7FA), const Color(0xFFFFFFFF)];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonaOnboardingViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isCompleted) {
          return _SuccessScreen(
            onContinue: () => context.go('/onboarding'),
          );
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: getBgGradient(context),
              ),
            ),
            child: SafeArea(
              child: _OnboardingCard(viewModel: viewModel),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _OnboardingCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PersonaOnboardingView.getBgCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _PersonaOnboardingView.getTextSecondary(context).withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top gradient bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _PersonaOnboardingView.primaryColor,
                    _PersonaOnboardingView.secondaryColor,
                    _PersonaOnboardingView.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(),
                  const SizedBox(height: 32),
                  _ProgressIndicator(
                    currentStep: viewModel.currentStep + 1,
                    totalSteps: viewModel.totalSteps,
                    progress: viewModel.progress,
                  ),
                  const SizedBox(height: 32),
                  _QuestionContent(viewModel: viewModel),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorMessage(message: viewModel.errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  _NavigationButtons(viewModel: viewModel),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (viewModel.isSubmitting) _LoadingOverlay(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              _PersonaOnboardingView.primaryColor,
              _PersonaOnboardingView.secondaryColor,
            ],
          ).createShader(bounds),
          child: Text(
            '✨ IdeaSpark',
            style: GoogleFonts.syne(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('persona_tagline'),
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _PersonaOnboardingView.getTextSecondary(context),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double progress;

  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('persona_progress'),
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _PersonaOnboardingView.getTextSecondary(context),
                letterSpacing: 1,
              ),
            ),
            Text(
              '$currentStep/$totalSteps',
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _PersonaOnboardingView.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            color: _PersonaOnboardingView.getBgElevated(context),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _PersonaOnboardingView.primaryColor,
                      _PersonaOnboardingView.secondaryColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _QuestionContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    Widget questionWidget;

    switch (viewModel.currentStep) {
      case 0:
        questionWidget = _ProfileQuestion(viewModel: viewModel);
        break;
      case 1:
        questionWidget = _GoalQuestion(viewModel: viewModel);
        break;
      case 2:
        questionWidget = _NicheQuestion(viewModel: viewModel);
        break;
      case 3:
        questionWidget = _MainPlatformQuestion(viewModel: viewModel);
        break;
      case 4:
        questionWidget = _PlatformsQuestion(viewModel: viewModel);
        break;
      case 5:
        questionWidget = _ContentStyleQuestion(viewModel: viewModel);
        break;
      case 6:
        questionWidget = _ToneQuestion(viewModel: viewModel);
        break;
      case 7:
        questionWidget = _AudienceQuestion(viewModel: viewModel);
        break;
      case 8:
        questionWidget = _AudienceAgeQuestion(viewModel: viewModel);
        break;
      case 9:
        questionWidget = _LanguageAndCtaQuestion(viewModel: viewModel);
        break;
      default:
        questionWidget = const SizedBox();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: questionWidget,
    );
  }
}

// Question widgets with updated design
class _ProfileQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _ProfileQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q1_title'),
      subtitle: context.tr('persona_q1_subtitle'),
      child: Column(
        children: ProfileType.values.map((type) {
          return _OptionCard(
            isSelected: viewModel.selectedProfile == type,
            onTap: () => viewModel.selectProfile(type),
            label: type.localizedLabel(locale),
            description: type.localizedDescription(locale),
          );
        }).toList(),
      ),
    );
  }
}

class _GoalQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _GoalQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q2_title'),
      subtitle: context.tr('persona_q2_subtitle'),
      child: Column(
        children: ContentGoal.values.map((goal) {
          return _OptionCard(
            isSelected: viewModel.selectedGoal == goal,
            onTap: () => viewModel.selectGoal(goal),
            label: goal.localizedLabel(locale),
            description: goal.localizedDescription(locale),
          );
        }).toList(),
      ),
    );
  }
}

class _NicheQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _NicheQuestion({required this.viewModel});

  // value = French label sent to backend, labelEn = English display
  static const List<Map<String, String>> nicheOptions = [
    {'value': 'Business', 'labelEn': 'Business'},
    {'value': 'E-commerce', 'labelEn': 'E-commerce'},
    {'value': 'Beauté', 'labelEn': 'Beauty'},
    {'value': 'Fitness', 'labelEn': 'Fitness'},
    {'value': 'Tech', 'labelEn': 'Tech'},
    {'value': 'Lifestyle', 'labelEn': 'Lifestyle'},
    {'value': 'Éducation', 'labelEn': 'Education'},
    {'value': 'Autre', 'labelEn': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q3_title'),
      subtitle: context.tr('persona_q3_subtitle'),
      child: Column(
        children: nicheOptions.map((niche) {
          final value = niche['value']!;
          final isSelected = viewModel.selectedNiches.contains(value);
          return _OptionCard(
            isSelected: isSelected,
            onTap: () => viewModel.toggleNiche(value),
            label: locale == 'en' ? niche['labelEn']! : value,
            description: '',
            isMultiSelect: true,
          );
        }).toList(),
      ),
    );
  }
}

class _MainPlatformQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _MainPlatformQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _QuestionLayout(
      title: context.tr('persona_q4_title'),
      subtitle: context.tr('persona_q4_subtitle'),
      child: Column(
        children: viewModel.mainPlatformOptions.map((platform) {
          final isSelected = viewModel.mainPlatform == platform['value'];
          return _OptionCard(
            isSelected: isSelected,
            onTap: () => viewModel.selectMainPlatform(platform['value']!),
            label: platform['label']!,
            description: '',
          );
        }).toList(),
      ),
    );
  }
}

class _PlatformsQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _PlatformsQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _QuestionLayout(
      title: context.tr('persona_q5_title'),
      subtitle: context.tr('persona_q5_subtitle'),
      child: Column(
        children: viewModel.frequentPlatformOptions.map((platform) {
          final isSelected = viewModel.selectedPlatforms.contains(platform['value']);
          return _OptionCard(
            isSelected: isSelected,
            onTap: () => viewModel.togglePlatform(platform['value']!),
            label: platform['label']!,
            description: '',
            isMultiSelect: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ContentStyleQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _ContentStyleQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q6_title'),
      subtitle: context.tr('persona_q6_subtitle'),
      child: Column(
        children: ContentStyle.values.map((style) {
          return _OptionCard(
            isSelected: viewModel.selectedContentStyles.contains(style),
            onTap: () => viewModel.toggleContentStyle(style),
            label: style.localizedLabel(locale),
            description: style.localizedDescription(locale),
            isMultiSelect: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ToneQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _ToneQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q9_title'),
      subtitle: context.tr('persona_q9_subtitle'),
      child: Column(
        children: ContentTone.values.map((tone) {
          return _OptionCard(
            isSelected: viewModel.selectedTone == tone,
            onTap: () => viewModel.selectTone(tone),
            label: tone.localizedLabel(locale),
            description: tone.localizedDescription(locale),
          );
        }).toList(),
      ),
    );
  }
}

class _AudienceQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _AudienceQuestion({required this.viewModel});

  // value = French label sent to backend, labelEn = English display
  static const List<Map<String, String>> audienceOptions = [
    {'value': 'Étudiants', 'labelEn': 'Students'},
    {'value': 'Jeunes actifs', 'labelEn': 'Young professionals'},
    {'value': 'Femmes', 'labelEn': 'Women'},
    {'value': 'Hommes', 'labelEn': 'Men'},
    {'value': 'Entrepreneurs', 'labelEn': 'Entrepreneurs'},
    {'value': 'Mixte', 'labelEn': 'Mixed'},
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q7_title'),
      subtitle: context.tr('persona_q7_subtitle'),
      child: Column(
        children: audienceOptions.map((audience) {
          final value = audience['value']!;
          final isSelected = viewModel.selectedAudiences.contains(value);
          return _OptionCard(
            isSelected: isSelected,
            onTap: () => viewModel.toggleAudience(value),
            label: locale == 'en' ? audience['labelEn']! : value,
            description: '',
            isMultiSelect: true,
          );
        }).toList(),
      ),
    );
  }
}

class _AudienceAgeQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _AudienceAgeQuestion({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q8_title'),
      subtitle: context.tr('persona_q8_subtitle'),
      child: Column(
        children: AudienceAge.values.map((age) {
          return _OptionCard(
            isSelected: viewModel.selectedAudienceAge == age,
            onTap: () => viewModel.selectAudienceAge(age),
            label: age.localizedLabel(locale),
            description: age.localizedDescription(locale),
          );
        }).toList(),
      ),
    );
  }
}

class _LanguageAndCtaQuestion extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _LanguageAndCtaQuestion({required this.viewModel});

  // value = French label sent to backend, labelEn = English display
  static const List<Map<String, String>> ctaOptions = [
    {'value': 'Abonne-toi', 'labelEn': 'Subscribe'},
    {'value': 'Commente', 'labelEn': 'Comment'},
    {'value': 'Lien en bio', 'labelEn': 'Link in bio'},
    {'value': 'DM', 'labelEn': 'DM'},
    {'value': 'WhatsApp', 'labelEn': 'WhatsApp'},
    {'value': 'Commander', 'labelEn': 'Order'},
  ];

  // Localized labels for language options
  static const Map<String, String> _langLabelEn = {
    'fr': 'French',
    'ar': 'Arabic',
    'en': 'English',
    'mix': 'Mixed',
  };

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>().locale;
    return _QuestionLayout(
      title: context.tr('persona_q10_title'),
      subtitle: context.tr('persona_q10_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('persona_language_label'),
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PersonaOnboardingView.getTextSecondary(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...viewModel.languageOptions.map((lang) {
            final isSelected = viewModel.language == lang['value'];
            final displayLabel = locale == 'en'
                ? (_langLabelEn[lang['value']] ?? lang['label']!)
                : lang['label']!;
            return _OptionCard(
              isSelected: isSelected,
              onTap: () => viewModel.selectLanguage(lang['value']!),
              label: displayLabel,
              description: '',
            );
          }),
          const SizedBox(height: 24),
          Text(
            context.tr('persona_cta_label'),
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PersonaOnboardingView.getTextSecondary(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...ctaOptions.map((cta) {
            final value = cta['value']!;
            final isSelected = viewModel.selectedCTAs.contains(value);
            return _OptionCard(
              isSelected: isSelected,
              onTap: () => viewModel.toggleCta(value),
              label: locale == 'en' ? cta['labelEn']! : value,
              description: '',
              isMultiSelect: true,
            );
          }),
        ],
      ),
    );
  }
}

// Reusable components
class _QuestionLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _QuestionLayout({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _PersonaOnboardingView.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.spaceMono(
            fontSize: 13,
            color: _PersonaOnboardingView.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;
  final String label;
  final String description;
  final bool isMultiSelect;

  const _OptionCard({
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.description,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _PersonaOnboardingView.primaryColor.withOpacity(0.1)
              : _PersonaOnboardingView.getBgElevated(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _PersonaOnboardingView.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio or Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? _PersonaOnboardingView.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? _PersonaOnboardingView.primaryColor
                      : _PersonaOnboardingView.getTextTertiary(context),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(isMultiSelect ? 6 : 10),
              ),
              child: isSelected
                  ? Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          color: _PersonaOnboardingView.getBgColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _PersonaOnboardingView.primaryColor
                          : _PersonaOnboardingView.getTextPrimary(context),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: _PersonaOnboardingView.getTextSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  final PersonaOnboardingViewModel viewModel;

  const _NavigationButtons({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!viewModel.isFirstStep)
          Expanded(
            child: OutlinedButton(
              onPressed: viewModel.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _PersonaOnboardingView.getBgElevated(context),
                side: BorderSide(
                  color: _PersonaOnboardingView.getTextSecondary(context).withOpacity(0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('persona_back'),
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _PersonaOnboardingView.getTextSecondary(context),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        if (!viewModel.isFirstStep) const SizedBox(width: 12),
        Expanded(
          flex: viewModel.isFirstStep ? 1 : 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: viewModel.canProceed()
                  ? const LinearGradient(
                      colors: [
                        _PersonaOnboardingView.primaryColor,
                        _PersonaOnboardingView.secondaryColor,
                      ],
                    )
                  : null,
              color: viewModel.canProceed() ? null : _PersonaOnboardingView.getBgElevated(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: viewModel.canProceed()
                  ? [
                      BoxShadow(
                        color: _PersonaOnboardingView.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: viewModel.canProceed()
                  ? () async {
                      if (viewModel.isLastStep) {
                        await viewModel.submitPersona();
                      } else {
                        viewModel.nextStep();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                viewModel.isLastStep ? context.tr('persona_finish') : context.tr('persona_next'),
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: viewModel.canProceed()
                      ? _PersonaOnboardingView.getBgColor(context)
                      : _PersonaOnboardingView.getTextTertiary(context),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PersonaOnboardingView.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _PersonaOnboardingView.secondaryColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: _PersonaOnboardingView.secondaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: _PersonaOnboardingView.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: _PersonaOnboardingView.getBgColor(context).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                _PersonaOnboardingView.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const _SuccessScreen({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _PersonaOnboardingView.getBgGradient(context),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      _PersonaOnboardingView.primaryColor,
                      _PersonaOnboardingView.secondaryColor,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    context.tr('persona_success_title'),
                    style: GoogleFonts.syne(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('persona_success_subtitle'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    color: _PersonaOnboardingView.getTextSecondary(context),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _PersonaOnboardingView.primaryColor,
                        _PersonaOnboardingView.secondaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _PersonaOnboardingView.primaryColor.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr('persona_success_button'),
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _PersonaOnboardingView.getBgColor(context),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
