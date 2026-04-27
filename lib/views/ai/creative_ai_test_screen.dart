import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/creative_ai_service.dart';
import '../../services/trending_hashtags_service.dart';
import '../../models/post_analysis.dart';
import '../../models/optimal_timing.dart';
import '../../widgets/post_score_card.dart';
import '../../widgets/viral_hooks_selector.dart';
import '../../widgets/optimal_timing_calendar.dart';

class CreativeAITestScreen extends StatefulWidget {
  const CreativeAITestScreen({super.key});

  @override
  State<CreativeAITestScreen> createState() => _CreativeAITestScreenState();
}

class _CreativeAITestScreenState extends State<CreativeAITestScreen> {
  final captionController = TextEditingController();
  final hashtagsController = TextEditingController();
  
  PostAnalysis? analysis;
  OptimalTiming? timing;
  bool isAnalyzing = false;
  bool isLoadingTiming = false;
  bool isGeneratingHashtags = false;
  
  String selectedPlatform = 'instagram';
  String selectedContentType = 'post';

  @override
  void initState() {
    super.initState();
    _loadOptimalTiming();
  }

  @override
  void dispose() {
    captionController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadOptimalTiming() async {
    setState(() => isLoadingTiming = true);
    
    try {
      final result = await CreativeAIService.getOptimalTiming(
        platform: selectedPlatform,
        contentType: selectedContentType,
      );
      
      if (mounted) {
        setState(() {
          timing = result;
          isLoadingTiming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingTiming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur timing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateHashtags() async {
    if (captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une caption d\'abord'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isGeneratingHashtags = true);

    try {
      // Détecter la catégorie depuis la caption
      final caption = captionController.text.toLowerCase();
      String category = 'lifestyle';
      
      if (caption.contains('cosmetic') || caption.contains('makeup') || 
          caption.contains('beauty') || caption.contains('rouge')) {
        category = 'cosmetics';
      } else if (caption.contains('sport') || caption.contains('fitness')) {
        category = 'sports';
      } else if (caption.contains('fashion') || caption.contains('vêtement')) {
        category = 'fashion';
      } else if (caption.contains('food') || caption.contains('cuisine')) {
        category = 'food';
      } else if (caption.contains('tech') || caption.contains('digital')) {
        category = 'technology';
      }

      final hashtags = await TrendingHashtagsService.generateHashtags(
        brandName: 'Brand',
        postTitle: captionController.text.trim().split('\n').first,
        category: category,
        platform: selectedPlatform,
      );

      if (mounted) {
        setState(() {
          hashtagsController.text = hashtags.join(' ');
          isGeneratingHashtags = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${hashtags.length} hashtags générés !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isGeneratingHashtags = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzePost() async {
    if (captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une caption'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isAnalyzing = true);

    try {
      final hashtags = hashtagsController.text
          .split(' ')
          .where((h) => h.trim().isNotEmpty)
          .toList();

      final result = await CreativeAIService.analyzePost(
        caption: captionController.text.trim(),
        hashtags: hashtags,
        platform: selectedPlatform,
      );

      if (mounted) {
        setState(() {
          analysis = result;
          isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Score: ${result.overallScore}/100'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 22,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Générateur de Hooks',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sélecteur de Hooks Viraux
                    ViralHooksSelector(
                      platform: selectedPlatform,
                      onHookSelected: (hook) {
                        captionController.text = '$hook\n\n';
                      },
                    ),
                    const SizedBox(height: 20),

                    // 2. Formulaire Caption
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit, color: Colors.orange, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Votre Post',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Plateforme
                            Text(
                              'Plateforme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: ['instagram', 'tiktok', 'facebook', 'linkedin']
                                  .map((platform) {
                                final isSelected = selectedPlatform == platform;
                                return ChoiceChip(
                                  label: Text(
                                    platform,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : cs.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => selectedPlatform = platform);
                                    _loadOptimalTiming();
                                  },
                                  selectedColor: cs.primary,
                                  backgroundColor: cs.surfaceContainerHighest,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Caption
                            TextField(
                              controller: captionController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Caption',
                                hintText: 'Écrivez votre caption ici...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: cs.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Hashtags
                            TextField(
                              controller: hashtagsController,
                              decoration: InputDecoration(
                                labelText: 'Hashtags',
                                hintText: '#fitness #motivation #health',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: cs.surfaceContainerHighest,
                                prefixIcon: const Icon(Icons.tag),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Bouton générer hashtags
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: isGeneratingHashtags ? null : _generateHashtags,
                                icon: isGeneratingHashtags
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('🔥', style: TextStyle(fontSize: 16)),
                                label: Text(
                                  isGeneratingHashtags 
                                      ? 'Génération...' 
                                      : 'Générer des hashtags tendances',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bouton analyser
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isAnalyzing ? null : _analyzePost,
                                icon: isAnalyzing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.analytics, size: 20),
                                label: Text(
                                  isAnalyzing ? 'Analyse...' : '📊 Analyser le post',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Résultat de l'analyse
                    if (analysis != null) ...[
                      PostScoreCard(analysis: analysis!),
                      const SizedBox(height: 20),
                    ],

                    // 4. Timing optimal
                    if (isLoadingTiming)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (timing != null)
                      OptimalTimingCalendar(timing: timing!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
