import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import '../../widgets/campaign_stepper.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/auth_view_model.dart';

class CampaignPlannerScreen extends StatefulWidget {
  final Brand? brand;
  final Plan? existingPlan;

  const CampaignPlannerScreen({super.key, this.brand, this.existingPlan});

  @override
  State<CampaignPlannerScreen> createState() => _CampaignPlannerScreenState();
}

class _CampaignPlannerScreenState extends State<CampaignPlannerScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  String? _selectedBrandId;
  List<String> _selectedProductIds = [];

  double _totalBudget = 2500.0;
  List<Map<String, dynamic>> _budgetAllocation = [
    {'name': 'Contenu & Création', 'percent': 40, 'color': const Color(0xFF6D4ED3)},
    {'name': 'Publicité (Ads)', 'percent': 40, 'color': const Color(0xFFE8366B)},
    {'name': 'Influenceurs', 'percent': 20, 'color': const Color(0xFF0EBFA1)},
  ];
  String _selectedCurrency = '€';
  bool _isSaving = false;

  // Empty for now

  @override
  void initState() {
    super.initState();
    _selectedBrandId = widget.brand?.id ?? widget.existingPlan?.brandId;
    
    // Pre-fill if existing plan
    if (widget.existingPlan != null) {
      _totalBudget = widget.existingPlan!.projectDNA.budget.totalBudget.toDouble();
      // You could pre-fill more fields here (phases, content, etc.)
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
    });
  }

  final List<String> _stepTitles = [
    'Infos de base',
    'Produits',
    'Budget',
    'Review',
  ];

  final List<String> _stepSubtitles = [
    'Étape 1 sur 4 — Infos de base',
    'Étape 2 sur 4 — Produits de la marque',
    'Étape 3 sur 4 — Budget & KPIs',
    'Étape 4 sur 4 — Revue finale',
  ];

  @override
  Widget build(BuildContext context) {
    final isSuccess = _currentStep == 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        children: [
          _buildTopBar(context, isSuccess),
          Expanded(
            child: isSuccess ? _buildSuccessScreen() : _buildStepperContent(),
          ),
          if (!isSuccess) _buildStickyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isSuccess) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 18,
        left: 20,
        right: 20,
      ),
      color: const Color(0xFF6D4ED3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentStep > 0 && !isSuccess) {
                    setState(() => _currentStep--);
                  } else {
                    context.pop();
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isSuccess ? 'Succès !' : 'Nouvelle Campagne',
                style: GoogleFonts.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              isSuccess ? 'Campagne créée avec succès !' : _stepSubtitles[_currentStep],
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperContent() {
    return Column(
      children: [
        CampaignStepper(
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          stepTitles: _stepTitles,
          onStepTapped: (index) {
            if (index <= _currentStep) {
              setState(() => _currentStep = index);
            }
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: _buildCurrentStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildBottomButtonsForStep(),
      ),
    );
  }

  Widget _buildBottomButtonsForStep() {
    switch (_currentStep) {
      case 0:
        return _buildMainButton('Continuer → Produits ✦', () => setState(() => _currentStep++));
      case 1:
        return Row(
          children: [
            Expanded(child: _buildBackButton(() => setState(() => _currentStep--))),
            const SizedBox(width: 12),
            Expanded(child: _buildMainButton('Budget & KPIs ✦', () => setState(() => _currentStep++))),
          ],
        );
      case 2:
        return Row(
          children: [
            Expanded(child: _buildBackButton(() => setState(() => _currentStep--))),
            const SizedBox(width: 12),
            Expanded(child: _buildMainButton('Revoir & Lancer ✦', () => setState(() => _currentStep++))),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSaving)
              const Center(child: CircularProgressIndicator())
            else
              _buildMainButton('🚀 Lancer la Campagne', _saveCampaign),
            const SizedBox(height: 8),
            if (!_isSaving)
              _buildSecButton('← Modifier', () => setState(() => _currentStep--)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _saveCampaign() async {
    final brandVm = context.read<BrandViewModel>();
    final planVm = context.read<PlanViewModel>();

    if (brandVm.brands.isEmpty) return;

    final brand = _selectedBrandId != null 
        ? brandVm.brands.firstWhere((b) => b.id == _selectedBrandId)
        : brandVm.brands.first;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> planData = {
        'name': 'Campagne ${brand.name} - ${DateTime.now().day}/${DateTime.now().month}',
        'brandId': brand.id,
        'objective': 'brand_awareness',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
        'durationWeeks': 12,
        'platforms': ['Instagram', 'Facebook', 'TikTok'],
        'productIds': _selectedProductIds,
        'projectDNA': {
          'budget': {
            'totalBudget': _totalBudget.toInt(),
          }
        },
      };

      if (widget.existingPlan == null) {
        planData['phases'] = [];
      }

      if (widget.existingPlan != null) {
        await PlanService.updatePlan(widget.existingPlan!.id!, planData);
        
        // If the plan has 0 phases, we need to generate them now!
        if (widget.existingPlan!.phases.isEmpty) {
          final generated = await planVm.generatePlanStructure(widget.existingPlan!.id!);
          if (mounted) {
            setState(() => _isSaving = false);
            if (generated == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan mis à jour, mais erreur de génération AI: ${planVm.error}')));
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campagne mise à jour et générée avec succès ! 🚀')));
              Navigator.pop(context);
              return;
            }
          }
        }
        
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campagne mise à jour !')));
          Navigator.pop(context);
        }
      } else {
        final newPlan = await planVm.createAndGenerate(planData, brand.id!);
        if (mounted) {
          setState(() => _isSaving = false);
          if (newPlan == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${planVm.error ?? "Échec de la création"}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Campagne créée et générée avec succès ! 🚀')),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: $e')),
        );
      }
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStepInfos();
      case 1: return _buildStepProduits();
      case 2: return _buildStepBudget();
      case 3: return _buildStepReview();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStepInfos() {
    return Consumer<BrandViewModel>(
      builder: (context, brandVm, _) {
        // Auto-select brand if only one and none selected
        if (_selectedBrandId == null && brandVm.brands.length == 1) {
          _selectedBrandId = brandVm.brands.first.id;
        } else if (_selectedBrandId == null && widget.brand != null) {
          _selectedBrandId = widget.brand!.id;
        }

        return Column(
          children: [
            _buildAiBanner(
              'Assistant Campagne IA',
              'Remplis les infos — je génère ta roadmap complète automatiquement.',
              '✦',
              [const Color(0xFF6D4ED3), const Color(0xFFE8366B)],
            ),
            _buildCard(
              'Détails de la campagne',
              '📋',
              const Color(0xFFF0EEFF),
              [
                _buildTextField('Nom de la campagne', 'ex. Lancement Été 2025', initialValue: 'Lancement Été 2025'),
                
                // Real brands from BrandViewModel
                _buildLabel('Marque associée'),
                const SizedBox(height: 5),
                brandVm.isLoading 
                  ? const LinearProgressIndicator() 
                  : _buildBrandDropdown(brandVm.brands),
                const SizedBox(height: 11),

                _buildDropdownField('Objectif principal', ['🚀 Notoriété', '📈 Leads', '💰 Ventes', '❤️ Engagement']),
                _buildDropdownField('Durée cible', ['4 semaines', '6 semaines', '8 semaines', '12 semaines']),
              ],
            ),
            _buildCard(
              'Plateformes cibles',
              '📡',
              const Color(0xFFFFF0F5),
              [
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _buildChip('TikTok', const Color(0xFF010101), true),
                    _buildChip('Instagram', const Color(0xFFE1306C), true),
                    _buildChip('YouTube', const Color(0xFFFF0000), false),
                    _buildChip('Facebook', const Color(0xFF1877F2), false),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        );
      }
    );
  }

  Widget _buildLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B5F85)));
  }

  Widget _buildBrandDropdown(List<Brand> brands) {
    if (brands.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: const Text('No brands found. Create one first.', style: TextStyle(fontSize: 12, color: Colors.red)),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedBrandId,
      items: [
        ...brands.map((b) => DropdownMenuItem(
          value: b.id,
          child: Text(b.name, style: const TextStyle(fontSize: 13)),
        )),
        const DropdownMenuItem(value: 'new', child: Text('+ Nouvelle marque', style: TextStyle(fontSize: 13, color: Color(0xFF6D4ED3)))),
      ],
      onChanged: (v) {
        if (v == 'new') {
          context.push('/brand-form');
        } else {
          setState(() => _selectedBrandId = v);
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9F8FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
    );
  }

  Widget _buildStepProduits() {
    return Consumer<BrandViewModel>(
      builder: (context, brandVm, _) {
        final brand = _selectedBrandId != null 
            ? brandVm.brands.firstWhere((b) => b.id == _selectedBrandId, orElse: () => brandVm.brands.first)
            : brandVm.brands.isNotEmpty ? brandVm.brands.first : null;

        if (brand == null) return const Center(child: Text("Aucune marque sélectionnée"));

        final products = brand.products;

        return Column(
          children: [
            _buildAiBanner(
              'Produits Cibles',
              'Sélectionne les produits que cette campagne doit promouvoir.',
              '🛍️',
              [const Color(0xFFE8366B), const Color(0xFF6D4ED3)],
            ),
            if (products.isEmpty)
              _buildCard(
                'Aucun Produit',
                '🛒',
                const Color(0xFFF0EEFF),
                [
                  const Text("Cette marque n'a aucun produit dans son catalogue.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildSecButton("Ajouter des produits (Bientôt)", () {}),
                ],
              )
            else
              _buildCard(
                'Catalogue de la marque',
                '📦',
                const Color(0xFFF0EEFF),
                [
                  ...products.map((p) {
                    final isSelected = _selectedProductIds.contains(p.id);
                    return CheckboxListTile(
                      title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isSelected,
                      activeColor: const Color(0xFF6D4ED3),
                      onChanged: (val) {
                        setState(() {
                          if (val == true && p.id != null) {
                            _selectedProductIds.add(p.id!);
                          } else {
                            _selectedProductIds.remove(p.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
          ],
        );
      }
    );
  }

  Widget _buildStepBudget() {
    return Column(
      children: [
        _buildAiBanner(
          'Optimisation du Budget',
          'Ajuste les curseurs pour voir l\'impact sur tes KPIs.',
          '💰',
          [const Color(0xFF6D4ED3), const Color(0xFF1A1040)],
        ),

        // Budget Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildBudgetPreset('🎯 Performance', 'Max Ads', const Color(0xFFE8366B)),
              const SizedBox(width: 8),
              _buildBudgetPreset('🎨 Créatif', 'Max Contenu', const Color(0xFF6D4ED3)),
              const SizedBox(width: 8),
              _buildBudgetPreset('🤝 Social', 'Max Influence', const Color(0xFF0EBFA1)),
            ],
          ),
        ),

        _buildCard(
          'Budget Global',
          '💸',
          const Color(0xFFF9F8FF),
          [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DEVISE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3), letterSpacing: 1.2)),
                Row(
                  children: [
                    _buildCurrencyChip('€'),
                    const SizedBox(width: 4),
                    _buildCurrencyChip('\$'),
                    const SizedBox(width: 4),
                    _buildCurrencyChip('DT'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MONTANT TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3), letterSpacing: 1.2)),
                Text('${_totalBudget.toInt()} $_selectedCurrency', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF6D4ED3))),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _totalBudget,
              min: 500,
              max: 10000,
              divisions: 19,
              activeColor: const Color(0xFF6D4ED3),
              inactiveColor: const Color(0xFF6D4ED3).withValues(alpha: 0.1),
              onChanged: (val) => setState(() => _totalBudget = val),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildCard(
          'Répartition par poste',
          '📊',
          Colors.white,
          [
            ..._budgetAllocation.map((item) {
              final amount = (_totalBudget * item['percent'] / 100).toInt();
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$amount $_selectedCurrency (${item['percent']}%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item['color'])),
                    ],
                  ),
                  Slider(
                    value: item['percent'].toDouble(),
                    min: 0,
                    max: 100,
                    activeColor: item['color'],
                    inactiveColor: item['color'].withValues(alpha: 0.1),
                    onChanged: (val) {
                      setState(() {
                        item['percent'] = val.toInt();
                      });
                    },
                  ),
                ],
              );
            }),
            
            const SizedBox(height: 8),
            
            // Add Category Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _budgetAllocation.add({
                      'name': 'Autre dépense',
                      'percent': 10,
                      'color': Colors.orange,
                    });
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter une catégorie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6D4ED3),
                  side: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.2)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyChip(String symbol) {
    final isSelected = _selectedCurrency == symbol;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = symbol),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D4ED3) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.2)),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF6D4ED3),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPreset(String label, String sub, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (sub.contains('Ads')) {
            _budgetAllocation = [
              {'name': 'Contenu', 'percent': 20, 'color': const Color(0xFF6D4ED3)},
              {'name': 'Publicité (Ads)', 'percent': 70, 'color': color},
              {'name': 'Divers', 'percent': 10, 'color': Colors.grey},
            ];
          } else if (sub.contains('Contenu')) {
            _budgetAllocation = [
              {'name': 'Production Vidéo', 'percent': 60, 'color': color},
              {'name': 'Ads Support', 'percent': 20, 'color': const Color(0xFFE8366B)},
              {'name': 'Post-Prod', 'percent': 20, 'color': Colors.purple},
            ];
          } else {
            _budgetAllocation = [
              {'name': 'Influenceurs', 'percent': 60, 'color': color},
              {'name': 'Management', 'percent': 20, 'color': Colors.blue},
              {'name': 'Ads Retargeting', 'percent': 20, 'color': const Color(0xFFE8366B)},
            ];
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1040))),
            Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepReview() {
    return Column(
      children: [
        _buildAiBanner(
          'Campagne prête !',
          'IA : 94% de cohérence stratégique.',
          '🎯',
          [const Color(0xFF1A1040), const Color(0xFF6D4ED3)],
        ),
        _buildCard(
          'Récapitulatif',
          '📋',
          const Color(0xFFF0EEFF),
          [
            _buildReviewRow('Campagne', 'Lancement Été 2025'),
            _buildReviewRow('Budget', '${_totalBudget.toInt()} $_selectedCurrency', valueColor: const Color(0xFF6D4ED3)),
            _buildReviewRow('ROI estimé', '3.2× 📈', valueColor: const Color(0xFF0EBFA1)),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'Campagne lancée !',
            style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1040)),
          ),
          const SizedBox(height: 20),
          _buildMainButton('📊 Voir le Dashboard ↗', () {
             final planVm = context.read<PlanViewModel>();
             if (planVm.plans.isNotEmpty) {
               planVm.setCurrentPlan(planVm.plans.first);
             }
             context.go('/calendar');
          }),
          const SizedBox(height: 8),
          _buildSecButton('+ Nouvelle campagne', () => setState(() => _currentStep = 0)),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildAiBanner(String title, String text, String icon, List<Color> colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.syne(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(235))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String icon, Color iconBg, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 13))),
              ),
              const SizedBox(width: 7),
              Text(title, style: GoogleFonts.syne(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1040))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B5F85))),
            const SizedBox(height: 5),
          ],
          TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF9F8FF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B5F85))),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: items.first,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) {},
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9F8FF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6D4ED3).withValues(alpha: 0.1) : const Color(0xFFF9F8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF6D4ED3) : const Color(0xFF6D4ED3).withValues(alpha: 0.12), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF6D4ED3) : const Color(0xFF6B5F85))),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String key, String val, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12)),
          Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF8B6FE8)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6D4ED3).withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF6D4ED3)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onTap) {
    return _buildSecButton('← Retour', onTap);
  }
}
