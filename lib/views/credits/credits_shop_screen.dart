import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/credits_view_model.dart';

class CreditsShopScreen extends StatelessWidget {
  const CreditsShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = context.accentColor;
    return ChangeNotifierProvider(
      create: (_) => CreditsViewModel(),
      child: Consumer<CreditsViewModel>(
        builder: (context, vm, _) {
          return DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('shop'),
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 20, decoration: TextDecoration.none)),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [colorScheme.primary, accent],
                        ).createShader(bounds),
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            '${vm.balance}',
                            style: GoogleFonts.syne(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('credits_shop'),
                  style: GoogleFonts.syne(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('buy_credits_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 32),
                ...CreditsViewModel.packs.map((pack) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _CreditPack(
                      pack: pack,
                      colorScheme: colorScheme,
                      accent: accent,
                      onBuy: () => context.push(
                        '/payment',
                        extra: {
                          'name': pack.name,
                          'credits': pack.credits,
                          'price': pack.price,
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

class _CreditPack extends StatelessWidget {
  final CreditPack pack;
  final ColorScheme colorScheme;
  final Color accent;
  final VoidCallback onBuy;

  const _CreditPack({
    required this.pack,
    required this.colorScheme,
    required this.accent,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (pack.popular)
          Positioned(
            top: 16,
            right: -32,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              transform: Matrix4.rotationZ(0.785),
              child: Text(
                context.tr('popular'),
                style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pack.popular ? colorScheme.primary : colorScheme.outlineVariant,
              width: pack.popular ? 2 : 1,
            ),
            boxShadow: pack.popular
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.name,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colorScheme.primary, accent],
                ).createShader(bounds),
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    pack.credits,
                    style: GoogleFonts.syne(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pack.price,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pack.description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('buy'), style: TextStyle(decoration: TextDecoration.none, color: colorScheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
