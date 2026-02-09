import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/onboarding_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  static const _pageKeys = [
    ('💡', 'onboarding_title_1', 'onboarding_desc_1'),
    ('🎯', 'onboarding_title_2', 'onboarding_desc_2'),
    ('🚀', 'onboarding_title_3', 'onboarding_desc_3'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Consumer<OnboardingViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: vm.setPage,
                      itemCount: _pageKeys.length,
                      itemBuilder: (context, i) {
                        final (emoji, titleKey, descKey) = _pageKeys[i];
                        final title = context.tr(titleKey);
                        final desc = context.tr(descKey);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 1),
                              Text(emoji,
                                  style: const TextStyle(fontSize: 100)),
                              const SizedBox(height: 40),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.syne(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                desc,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),
                              const Spacer(flex: 2),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pageKeys.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              width: vm.currentPage == i ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: vm.currentPage == i
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (vm.isLastPage) {
                                    await vm.completeOnboarding();
                                    if (!context.mounted) return;
                                    context.go('/home');
                                  } else {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: Text(
                                    vm.isLastPage
                                        ? context.tr('start')
                                        : context.tr('continue'),
                                    style: GoogleFonts.syne(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!vm.isLastPage)
                          TextButton(
                            onPressed: () async {
                              await vm.completeOnboarding();
                              if (!context.mounted) return;
                              context.go('/home');
                            },
                            child: Text(
                              context.tr('skip'),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
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
