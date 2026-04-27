import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';

class BusinessIdeasFormScreen extends StatefulWidget {
  const BusinessIdeasFormScreen({super.key});

  @override
  State<BusinessIdeasFormScreen> createState() => _BusinessIdeasFormScreenState();
}

class _BusinessIdeasFormScreenState extends State<BusinessIdeasFormScreen> {
  final _sectorController = TextEditingController();
  final _skillsController = TextEditingController();
  String _budget = 'Petit (<5K€)';
  String _time = 'Side Hustle';
  String _location = 'En ligne';
  bool _recurrent = true;
  bool _scalable = true;
  bool _lowCompetition = false;

  static const _budgets = ['Petit (<5K€)', 'Moyen (5-20K€)', 'Élevé (>20K€)'];
  static const _times = ['Side Hustle', 'Full-time'];
  static const _locations = ['En ligne', 'Local', 'Hybride'];

  @override
  void dispose() {
    _sectorController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

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
              _buildHeader(context, colorScheme),
              _buildInput(colorScheme, context.tr('sector'), _sectorController, context.tr('sector_hint')),
              _buildChipGroup(colorScheme, context.tr('startup_budget'), _budgets, _budget, (v) => setState(() => _budget = v)),
              _buildInput(colorScheme, context.tr('skills'), _skillsController, context.tr('skills_hint')),
              _buildChipGroup(colorScheme, context.tr('time_available'), _times, _time, (v) => setState(() => _time = v)),
              _buildChipGroup(colorScheme, context.tr('location'), _locations, _location, (v) => setState(() => _location = v)),
              const SizedBox(height: 12),
              Text(context.tr('extra_prefs'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              _buildSwitch(colorScheme, context.tr('recurring_model'), _recurrent, (v) => setState(() => _recurrent = v)),
              _buildSwitch(colorScheme, context.tr('scalable'), _scalable, (v) => setState(() => _scalable = v)),
              _buildSwitch(colorScheme, context.tr('low_competition'), _lowCompetition, (v) => setState(() => _lowCompetition = v)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/loading', extra: '/business-idea-detail'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(context.tr('generate_business')),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        context.tr('new_business_idea'),
        style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildInput(ColorScheme colorScheme, String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup(ColorScheme colorScheme, String label, List<String> options, String selected, ValueChanged<String> onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((o) {
              final isSelected = o == selected;
              return GestureDetector(
                onTap: () => onSelect(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
                  ),
                  child: Text(o, style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : colorScheme.onSurface)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(ColorScheme colorScheme, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
          Switch(value: value, onChanged: onChanged, activeThumbColor: colorScheme.primary),
        ],
      ),
    );
  }
}
