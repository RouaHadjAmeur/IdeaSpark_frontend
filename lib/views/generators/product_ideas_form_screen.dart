import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';

class ProductIdeasFormScreen extends StatefulWidget {
  const ProductIdeasFormScreen({super.key});

  @override
  State<ProductIdeasFormScreen> createState() => _ProductIdeasFormScreenState();
}

class _ProductIdeasFormScreenState extends State<ProductIdeasFormScreen> {
  final _nicheController = TextEditingController();
  String _category = 'Digital';
  String _clientType = 'B2C';
  double _budgetValue = 0.3;

  static const _categories = ['Physique', 'Digital', 'Service'];
  static const _clientTypes = ['B2B', 'B2C', 'B2B2C'];

  @override
  void dispose() {
    _nicheController.dispose();
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
              _buildChipGroup(colorScheme, context.tr('product_category'), _categories, _category, (v) => setState(() => _category = v)),
              _buildInput(colorScheme, context.tr('niche'), _nicheController, context.tr('product_niche_hint')),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('estimated_budget'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        thumbColor: colorScheme.primary,
                      ),
                      child: Slider(
                        value: _budgetValue,
                        onChanged: (v) => setState(() => _budgetValue = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0€', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        Text('5K€', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        Text('10K€', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        Text('20K€+', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildChipGroup(colorScheme, 'Type de client', _clientTypes, _clientType, (v) => setState(() => _clientType = v)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/loading', extra: '/product-idea-result'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(context.tr('generate_product')),
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
        context.tr('new_product_idea'),
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
}
