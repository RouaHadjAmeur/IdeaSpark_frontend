import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_localizations.dart';
import '../../view_models/home_view_model.dart';

class GeneratorsScreen extends StatelessWidget {
  const GeneratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access all your AI-powered creative tools in one place.',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: vm.generatorList.map((e) {
                  return _GeneratorCard(
                    icon: e.icon,
                    label: context.tr('gen_${e.typeId}'),
                    typeId: e.typeId,
                    onTap: () => context.push(_formRouteForType(e.typeId)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(cs, 'Saved Results'),
              _buildSavedResultsCard(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildSavedResultsCard(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_shared_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 16),
          const Text(
            'Your Library',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Check all your saved slogans, video ideas, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () => context.push('/saved-ideas'),
            child: const Text('View All Saved'),
          ),
        ],
      ),
    );
  }

  String _formRouteForType(String typeId) {
    switch (typeId) {
      case 'camera-coach':
        return '/camera-coach';
      case 'video':
        return '/video-ideas-form';
      case 'product':
        return '/product-ideas-form';
      case 'slogans':
        return '/slogans-form';
      default:
        return '/criteria';
    }
  }
}

class _GeneratorCard extends StatelessWidget {
  final String icon;
  final String label;
  final String typeId;
  final VoidCallback onTap;

  const _GeneratorCard({
    required this.icon,
    required this.label,
    required this.typeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
