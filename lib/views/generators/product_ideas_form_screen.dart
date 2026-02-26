import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/product_idea_view_model.dart';

class ProductIdeasFormScreen extends StatefulWidget {
  const ProductIdeasFormScreen({super.key});

  @override
  State<ProductIdeasFormScreen> createState() => _ProductIdeasFormScreenState();
}

class _ProductIdeasFormScreenState extends State<ProductIdeasFormScreen> {
  final _problemController = TextEditingController();
  final _nicheController = TextEditingController();
  
  bool _usePromptMode = false; // Par défaut le mode simple (ON)
  String _category = 'Digital';
  String _clientType = 'B2C';
  double _budgetValue = 0.3;

  static const _categories = ['Physique', 'Digital', 'Service'];
  static const _clientTypes = ['B2B', 'B2C', 'B2B2C'];

  @override
  void dispose() {
    _problemController.dispose();
    _nicheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<ProductIdeaViewModel>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme),
              
              // Switch pour basculer entre les modes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _usePromptMode ? 'Mode Prompt Simple' : 'Formulaire Classique',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Switch(
                    value: _usePromptMode,
                    onChanged: (value) {
                      setState(() {
                        _usePromptMode = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_usePromptMode) ...[
                // Mode Prompt Simple (Actuel)
                _buildInput(
                  colorScheme,
                  context.tr('product_problem'),
                  _problemController,
                  context.tr('product_problem_hint'),
                  maxLines: 5,
                ),
              ] else ...[
                // Mode Formulaire Classique (Ancien projet)
                _buildChipGroup(
                  colorScheme, 
                  context.tr('product_category'), 
                  _categories, 
                  _category, 
                  (v) => setState(() => _category = v)
                ),
                _buildInput(
                  colorScheme, 
                  context.tr('niche'), 
                  _nicheController, 
                  context.tr('product_niche_hint')
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('estimated_budget'), 
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)
                      ),
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
                _buildChipGroup(
                  colorScheme, 
                  'Type de client', 
                  _clientTypes, 
                  _clientType, 
                  (v) => setState(() => _clientType = v)
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: viewModel.isLoading ? null : _onGeneratePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: viewModel.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                          ),
                        )
                      : Text(context.tr('generate_product')),
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
      padding: const EdgeInsets.only(bottom: 24, top: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('new_product_idea'),
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInput(ColorScheme colorScheme, String label, TextEditingController controller, String hint, {int maxLines = 1}) {
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
            maxLines: maxLines,
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

  void _onGeneratePressed() async {
    String besoin = "";

    if (_usePromptMode) {
      besoin = _problemController.text.trim();
      if (besoin.isEmpty) {
        _showError('Merci de décrire le problème à résoudre');
        return;
      }
    } else {
      final niche = _nicheController.text.trim();
      if (niche.isEmpty) {
        _showError('${context.tr('niche')} est requis');
        return;
      }
      
      final budget = (_budgetValue * 10000).round();
      besoin = "Niche: $niche, Catégorie: $_category, Budget estimé: $budget€, Type de client: $_clientType";
    }

    final viewModel = context.read<ProductIdeaViewModel>();
    await viewModel.generateProductIdea(besoin: besoin);

    if (!mounted) return;

    if (viewModel.error != null) {
      _showError(viewModel.error!);
      return;
    }

    if (viewModel.idea != null) {
      context.push('/product-idea-result');
    }
  }

  void _showError(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
      ),
    );
  }
}
