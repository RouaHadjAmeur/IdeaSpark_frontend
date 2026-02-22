import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';

class TrendsAnalysisScreen extends StatefulWidget {
  const TrendsAnalysisScreen({super.key});

  @override
  State<TrendsAnalysisScreen> createState() => _TrendsAnalysisScreenState();
}

class _TrendsAnalysisScreenState extends State<TrendsAnalysisScreen> {
  int _tabIndex = 0;
  static const _tabKeys = ['for_you', 'video_tab', 'business_tab', 'products_tab'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('current_trends'),
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.successColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('trends_match_profile'),
                        style: TextStyle(fontSize: 13, color: context.successColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: List.generate(_tabKeys.length, (i) {
                  final active = _tabIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _tabKeys.length - 1 ? 8 : 0),
                      child: Material(
                        color: active ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: active ? colorScheme.primary : colorScheme.outlineVariant),
                            ),
                            child: Center(
                              child: Text(
                                context.tr(_tabKeys[i]),
                                style: TextStyle(fontSize: 13, color: active ? colorScheme.primary : colorScheme.onSurface),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('rising_trends'),
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              _TrendItem(colorScheme: colorScheme, icon: '💪', title: 'Fitness femmes 25-35', subtitle: '↗️ ${context.tr("growth")} +127% (7 jours)', growth: '+127%', isRising: true),
              _TrendItem(colorScheme: colorScheme, icon: '🛍️', title: 'E-commerce Tunisie', subtitle: '↗️ ${context.tr("growth")} +89% (7 jours)', growth: '+89%', isRising: true),
              _TrendItem(colorScheme: colorScheme, icon: '🧠', title: 'Productivité IA', subtitle: '↗️ ${context.tr("growth")} +156% (7 jours)', growth: '+156%', isRising: true),
              const SizedBox(height: 24),
              Text(
                context.tr('popular_now'),
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              _TrendItem(colorScheme: colorScheme, icon: '🎥', title: 'Side Hustle 2026', subtitle: context.tr('peak_interest'), growth: 'Top 5', isRising: false, accent: true),
              _TrendItem(colorScheme: colorScheme, icon: '📱', title: 'Apps No-Code', subtitle: context.tr('peak_interest'), growth: 'Top 3', isRising: false, accent: true),
              const SizedBox(height: 24),
              Text(
                context.tr('evergreen_potential'),
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              _TrendItem(colorScheme: colorScheme, icon: '💰', title: 'Investissement passif', subtitle: '📊 ${context.tr("stable_interest")}', growth: 'Stable', isRising: false, evergreen: true),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: Text(context.tr('see_all_trends')),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  final ColorScheme colorScheme;
  final String icon;
  final String title;
  final String subtitle;
  final String growth;
  final bool isRising;
  final bool accent;
  final bool evergreen;

  const _TrendItem({
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.growth,
    required this.isRising,
    this.accent = false,
    this.evergreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final success = context.successColor;
    final accentColor = context.accentColor;
    Color boxColor = colorScheme.primary.withValues(alpha: 0.2);
    Color subtitleColor = success;
    if (accent) {
      boxColor = accentColor.withValues(alpha: 0.2);
      subtitleColor = accentColor;
    } else if (evergreen) {
      boxColor = success.withValues(alpha: 0.2);
      subtitleColor = success;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Text(growth, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isRising ? context.successColor : colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
