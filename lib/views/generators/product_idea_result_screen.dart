import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/view_models/product_idea_view_model.dart';
import 'package:ideaspark/models/product_idea_model.dart';
import 'product_ideas_history_screen.dart';

class ProductIdeaResultScreen extends StatelessWidget {
  const ProductIdeaResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<ProductIdeaViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (viewModel.idea == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune idée produit générée.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retourne au formulaire et décris un problème à résoudre.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final idea = viewModel.idea!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      'Idée Produit',
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: viewModel.isSaving || viewModel.isCurrentIdeaSaved 
                        ? null 
                        : () => _saveIdea(context, viewModel),
                    icon: viewModel.isSaving 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurface),
                            ),
                          )
                        : viewModel.isCurrentIdeaSaved
                            ? Icon(Icons.bookmark_rounded, color: colorScheme.primary)
                            : Icon(Icons.bookmark_outline_rounded, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: viewModel.isCurrentIdeaSaved 
                          ? colorScheme.primary.withOpacity(0.1)
                          : colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: viewModel.isCurrentIdeaSaved 
                            ? colorScheme.primary 
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('📱', style: TextStyle(fontSize: 48))),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        idea.produit.nomDuProduit,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '📝 Description'),
                    const SizedBox(height: 8),
                    Text(
                      idea.produit.solution,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '🎯 Problème résolu'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: colorScheme.error, width: 3)),
                      ),
                      child: Text(
                        idea.produit.probleme,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '⚙️ Caractéristiques principales'),
                    const SizedBox(height: 8),
                    _FeatureRow(colorScheme: colorScheme, icon: '👥', text: 'Cible: ${idea.produit.cible}'),
                    _FeatureRow(colorScheme: colorScheme, icon: '💶', text: 'Modèle économique: ${idea.produit.modeleEconomique}'),
                    _FeatureRow(colorScheme: colorScheme, icon: '🧪', text: 'MVP: ${idea.produit.mvp}'),
                                      ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProductIdeasHistoryScreen(),
          ),
        ),
        icon: const Icon(Icons.history_rounded),
        label: const Text('Mes idées'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final ColorScheme colorScheme;
  final String text;

  const _Label({required this.colorScheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant));
  }
}

class _FeatureRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final String icon;
  final String text;

  const _FeatureRow({required this.colorScheme, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5))),
        ],
      ),
    );
  }
}

void _saveIdea(BuildContext context, ProductIdeaViewModel viewModel) async {
  await viewModel.saveCurrentIdea();
  
  if (!context.mounted) return;
  
  if (viewModel.saveError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${viewModel.saveError}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Idée produit sauvegardée avec succès !'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
