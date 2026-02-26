import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/auth_view_model.dart';
import 'package:ideaspark/view_models/slogan_view_model.dart';
import 'package:ideaspark/services/slogan_service.dart';

class SlogansFormScreen extends StatefulWidget {
  const SlogansFormScreen({super.key});

  @override
  State<SlogansFormScreen> createState() => _SlogansFormScreenState();
}

class _SlogansFormScreenState extends State<SlogansFormScreen> with TickerProviderStateMixin {
  // Section 1: Identité et Personnalité
  final _objectifController = TextEditingController();
  final _adjectifController = TextEditingController();
  final _promesseController = TextEditingController();
  
  // Section 2: Expérience et Valeur Utilisateur
  final _usageController = TextEditingController();
  final _obstacleController = TextEditingController();
  final _resultatController = TextEditingController();
  
  // Section 3: Positionnement Marché
  String _niveauGamme = 'Milieu de gamme';
  final _faiblesseController = TextEditingController();
  final _traitController = TextEditingController();
  
  // Section 4: Directives Rédactionnelles
  String _angle = 'Action';
  String _pilier = 'Qualité';
  String _niveauLangue = 'Courant';

  bool _usePromptRefiner = false;
  final _promptController = TextEditingController();
  bool _isRefiningPrompt = false;
  String? _refinedPrompt;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _niveauxGamme = ['Entrée de gamme', 'Milieu de gamme', 'Premium', 'Luxe'];
  static const _angles = ['Action', 'État d\'esprit'];
  static const _piliers = ['Prix', 'Qualité', 'Rapidité'];
  static const _niveauxLangue = ['Technique', 'Courant', 'Soutenu'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _objectifController.dispose();
    _adjectifController.dispose();
    _promesseController.dispose();
    _usageController.dispose();
    _obstacleController.dispose();
    _resultatController.dispose();
    _faiblesseController.dispose();
    _traitController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _generateSlogans() async {
    // Validation des champs obligatoires
    if (_promesseController.text.isEmpty || _obstacleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Veuillez remplir au minimum la promesse principale et l\'obstacle résolu')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final sloganVm = context.read<SloganViewModel>();
    await sloganVm.generateSlogansFromCopywritingForm(
      objectifCommunication: _objectifController.text,
      adjectifPersonnalite: _adjectifController.text,
      promessePrincipale: _promesseController.text,
      usageQuotidien: _usageController.text,
      obstacleResolu: _obstacleController.text,
      resultatConcret: _resultatController.text,
      niveauGamme: _niveauGamme,
      faiblesseCorrigee: _faiblesseController.text,
      traitDistinctif: _traitController.text,
      angle: _angle,
      pilierCommunication: _pilier,
      niveauLangue: _niveauLangue,
    );

    // Vérifier les erreurs
    if (sloganVm.error != null) {
      if (!mounted) return;
      
      // Vérifier si c'est une erreur d'authentification
      if (sloganVm.error!.contains('Authentification requise')) {
        final authVm = context.read<AuthViewModel>();
        final isLoggedIn = authVm.isLoggedIn;
        
        if (!isLoggedIn) {
          // Rediriger vers la page de connexion
          if (mounted) {
            context.go('/login');
            return;
          }
        }
      }
      
      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(sloganVm.error!)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Navigation vers les résultats
    if (mounted && sloganVm.slogans.isNotEmpty) {
      context.push('/slogans-results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sloganVm = context.watch<SloganViewModel>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mode Prompt Refiner',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Switch(
                      value: _usePromptRefiner,
                      onChanged: (value) {
                        setState(() {
                          _usePromptRefiner = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!_usePromptRefiner) ...[
                  _buildSectionHeader('Identité et Personnalité', colorScheme),
                  const SizedBox(height: 16),
                  _buildInput(
                    'Objectif de communication',
                    _objectifController,
                    'Ex: Positionner la marque comme innovante',
                    Icons.flag_rounded,
                    colorScheme,
                  ),
                  _buildInput(
                    'Adjectif de personnalité',
                    _adjectifController,
                    'Ex: Audacieux, moderne, authentique',
                    Icons.psychology_rounded,
                    colorScheme,
                  ),
                  _buildInput(
                    'Promesse principale *',
                    _promesseController,
                    'Ex: Simplifier votre quotidien',
                    Icons.star_rounded,
                    colorScheme,
                    required: true,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Expérience et Valeur Utilisateur', colorScheme),
                  const SizedBox(height: 16),
                  _buildInput(
                    'Usage quotidien',
                    _usageController,
                    'Ex: Gérer son budget en 5 minutes par jour',
                    Icons.schedule_rounded,
                    colorScheme,
                  ),
                  _buildInput(
                    'Obstacle majeur résolu *',
                    _obstacleController,
                    'Ex: La difficulté à suivre ses dépenses',
                    Icons.warning_rounded,
                    colorScheme,
                    required: true,
                  ),
                  _buildInput(
                    'Résultat concret immédiat',
                    _resultatController,
                    'Ex: Économiser 200€ par mois',
                    Icons.check_circle_rounded,
                    colorScheme,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Positionnement Marché', colorScheme),
                  const SizedBox(height: 16),
                  _buildChipGroup(
                    'Niveau de gamme',
                    _niveauxGamme,
                    _niveauGamme,
                    (value) => setState(() => _niveauGamme = value),
                    colorScheme,
                  ),
                  _buildInput(
                    'Faiblesse concurrente corrigée',
                    _faiblesseController,
                    'Ex: Interface complexe des concurrents',
                    Icons.shield_rounded,
                    colorScheme,
                  ),
                  _buildInput(
                    'Trait de caractère distinctif',
                    _traitController,
                    'Ex: Approche ludique et engageante',
                    Icons.auto_awesome_rounded,
                    colorScheme,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Directives Rédactionnelles', colorScheme),
                  const SizedBox(height: 16),
                  _buildChipGroup(
                    'Angle',
                    _angles,
                    _angle,
                    (value) => setState(() => _angle = value),
                    colorScheme,
                  ),
                  _buildChipGroup(
                    'Pilier de communication',
                    _piliers,
                    _pilier,
                    (value) => setState(() => _pilier = value),
                    colorScheme,
                  ),
                  _buildChipGroup(
                    'Niveau de langue',
                    _niveauxLangue,
                    _niveauLangue,
                    (value) => setState(() => _niveauLangue = value),
                    colorScheme,
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  _buildSectionHeader('Prompt libre', colorScheme),
                  const SizedBox(height: 16),
                  _buildPromptInput(colorScheme),
                  const SizedBox(height: 16),
                  _buildRefineButton(colorScheme),
                  if (_refinedPrompt != null && _refinedPrompt!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildRefinedPromptPreview(colorScheme),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 32),
                ],
                _buildGenerateButton(sloganVm, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Génération de Slogans',
          style: GoogleFonts.syne(
            fontSize: 32,
            fontWeight: FontWeight.w800,

            color: colorScheme.onSurface,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Formulaire professionnel pour créer des slogans percutants',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.primaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
    ColorScheme colorScheme, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                fontSize: 13,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup(
    String label,
    List<String> options,
    String selected,
    Function(String) onSelected,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = option == selected;
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onSelected(option),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(SloganViewModel sloganVm, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: sloganVm.isLoading
            ? null
            : () {
                if (_usePromptRefiner) {
                  _generateSlogansFromPrompt();
                } else {
                  _generateSlogans();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest;
            }
            return null;
          }),
        ),
        child: sloganVm.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Génération en cours...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '✨ Générer 10 Slogans',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPromptInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Décris ton besoin, ton audience et le ton souhaité',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _promptController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Ex: Je veux des slogans pour une application de productivité destinée aux freelances, ton motivant et professionnel.',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontSize: 13,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildRefineButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: _isRefiningPrompt ? null : _onRefinePromptPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isRefiningPrompt
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : Text(
                'Raffiner le prompt',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildRefinedPromptPreview(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prompt raffiné',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _refinedPrompt ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _onRefinePromptPressed() async {
    final raw = _promptController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Veuillez saisir un prompt à raffiner')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isRefiningPrompt = true;
    });

    try {
      final result = await SloganService.refinePrompt(prompt: raw);
      if (!mounted) return;
      setState(() {
        _refinedPrompt = result;
        _promptController.text = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefiningPrompt = false;
      });
    }
  }

  void _generateSlogansFromPrompt() async {
    final sloganVm = context.read<SloganViewModel>();
    final prompt = (_refinedPrompt ?? _promptController.text).trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Veuillez saisir ou raffiner un prompt avant de générer')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await sloganVm.generateSlogansFromCopywritingForm(
      objectifCommunication: prompt,
      adjectifPersonnalite: '',
      promessePrincipale: prompt,
      usageQuotidien: '',
      obstacleResolu: '',
      resultatConcret: '',
      niveauGamme: _niveauGamme,
      faiblesseCorrigee: '',
      traitDistinctif: '',
      angle: _angle,
      pilierCommunication: _pilier,
      niveauLangue: _niveauLangue,
    );

    if (sloganVm.error != null) {
      if (!mounted) return;
      if (sloganVm.error!.contains('Authentification requise')) {
        final authVm = context.read<AuthViewModel>();
        final isLoggedIn = authVm.isLoggedIn;
        if (!isLoggedIn) {
          if (mounted) {
            context.go('/login');
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(sloganVm.error!)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (mounted && sloganVm.slogans.isNotEmpty) {
      context.push('/slogans-results');
    }
  }
}
