import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SlogansFormScreen extends StatefulWidget {
  const SlogansFormScreen({super.key});

  @override
  State<SlogansFormScreen> createState() => _SlogansFormScreenState();
}

class _SlogansFormScreenState extends State<SlogansFormScreen> {
  final _brandController = TextEditingController();
  final _sectorController = TextEditingController();
  final _valuesController = TextEditingController();
  final _targetController = TextEditingController();
  String _tone = 'Inspirant';
  String _language = '🇫🇷 Français';

  static const _tones = ['Sérieux', 'Humoristique', 'Inspirant', 'Professionnel', 'Décalé'];
  static const _languages = ['🇫🇷 Français', '🇬🇧 English', '🇪🇸 Español', '🇩🇪 Deutsch'];

  @override
  void dispose() {
    _brandController.dispose();
    _sectorController.dispose();
    _valuesController.dispose();
    _targetController.dispose();
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
              _buildInput(colorScheme, 'Nom du produit / marque *', _brandController, 'Ex: FocusFlow'),
              _buildInput(colorScheme, 'Secteur d\'activité *', _sectorController, 'Ex: Application mobile productivité'),
              _buildInput(colorScheme, 'Valeurs de la marque (3-5 mots-clés)', _valuesController, 'Ex: Innovation, Simplicité, Efficacité'),
              _buildInput(colorScheme, 'Public cible', _targetController, 'Ex: Professionnels 25-40 ans'),
              _buildChipGroup(colorScheme, 'Ton souhaité', _tones, _tone, (v) => setState(() => _tone = v)),
              _buildChipGroup(colorScheme, 'Langue', _languages, _language, (v) => setState(() => _language = v)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/slogans-results'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('✍️ Générer 10 Slogans'),
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
              'Créer des Slogans',
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 48),
        ],
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
