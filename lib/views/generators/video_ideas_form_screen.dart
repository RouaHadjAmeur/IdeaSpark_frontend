import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import '../../models/video_generator_models.dart';
import '../../view_models/video_idea_form_view_model.dart';
import '../../services/video_generator_service.dart';
import '../../widgets/chip_group_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VideoIdeasFormScreen extends StatelessWidget {
  const VideoIdeasFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VideoIdeaFormViewModel(
        service: Provider.of<VideoIdeaGeneratorService>(context, listen: false),
      ),
      child: const _VideoIdeasFormView(),
    );
  }
}

class _VideoIdeasFormView extends StatelessWidget {
  const _VideoIdeasFormView();

  void _handleGenerate(BuildContext context, VideoIdeaFormViewModel viewModel) {
    final error = viewModel.validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final request = viewModel.buildRequest();

    // Pass data to loading screen which forwards to results
    context.push('/loading', extra: {
      'redirectTo': '/video-ideas-results',
      'data': request,
      'useRemoteGeneration': viewModel.useRemoteGeneration,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<VideoIdeaFormViewModel>(
            builder: (context, viewModel, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, colorScheme, context.tr('new_video_idea')),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Plus vous donnez de détails, plus les idées seront créatives et pertinentes!",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image Picker & Analysis Section
                  _buildImagePicker(context, viewModel, colorScheme),

                  // Section: Informations de Base
                  _buildSectionHeader(colorScheme, "📝 Informations de Base"),

                  _buildInputGroup(
                    colorScheme,
                    "Nom du Produit *",
                    "Ex: CrèmeLuxe, PowerBank Pro, ThéBio...",
                    viewModel.productName,
                    viewModel.updateProductName,
                    helperText: "Le nom complet de votre produit",
                  ),

                  _buildInputGroupWithSuggestions(
                    context,
                    colorScheme,
                    "Catégorie du Produit",
                    "Ex: Beauté, Tech...",
                    viewModel.productCategory,
                    viewModel.updateProductCategory,
                    VideoIdeaFormViewModel.categorySuggestions,
                  ),

                  _buildInputGroup(
                    colorScheme,
                    "Description du Produit",
                    "Décrivez brièvement votre produit...",
                    viewModel.useCases,
                    viewModel.updateUseCases,
                    maxLines: 3,
                    helperText: "Expliquez comment utiliser le produit et ses cas d'usage",
                  ),

                  // Enhanced Product Details Section
                  _buildExpandableSection(
                    context,
                    colorScheme,
                    "📦 Détails du Produit",
                    "Ingrédients, caractéristiques, avantages uniques",
                    [
                      _buildInputGroup(
                        colorScheme,
                        "Ingrédients / Composants",
                        "Ex: Vitamine C, Acide Hyaluronique, Aloe Vera",
                        viewModel.ingredients,
                        viewModel.updateIngredients,
                        maxLines: 2,
                        helperText: "Séparés par des virgules",
                      ),
                      _buildInputGroup(
                        colorScheme,
                        "Caractéristiques Techniques",
                        "Ex: Étanche, 5000mAh, Bluetooth 5.0",
                        viewModel.productFeatures,
                        viewModel.updateProductFeatures,
                        maxLines: 2,
                        helperText: "Séparées par des virgules",
                      ),
                      _buildInputGroup(
                        colorScheme,
                        "Point de Vente Unique (USP)",
                        "Ex: Seul produit certifié bio au Maroc",
                        viewModel.uniqueSellingPoint,
                        viewModel.updateUniqueSellingPoint,
                        maxLines: 2,
                        helperText: "Ce qui différencie votre produit",
                      ),
                    ],
                  ),

                  // Target Audience Section
                  _buildExpandableSection(
                    context,
                    colorScheme,
                    "🎯 Audience Cible",
                    "Définissez précisément votre public",
                    [
                      _buildInputGroupWithSuggestions(
                        context,
                        colorScheme,
                        "Type d'Audience",
                        "Ex: Étudiants, Mamans...",
                        viewModel.targetAudience,
                        viewModel.updateTargetAudience,
                        VideoIdeaFormViewModel.audienceSuggestions,
                      ),
                      _buildInputGroupWithSuggestions(
                        context,
                        colorScheme,
                        "Tranche d'Âge",
                        "Ex: 18-24 ans",
                        viewModel.ageRange,
                        viewModel.updateAgeRange,
                        VideoIdeaFormViewModel.ageRangeSuggestions,
                      ),
                      _buildInputGroup(
                        colorScheme,
                        "Preuve Sociale",
                        "Ex: 10k+ clients satisfaits, Note 4.8/5",
                        viewModel.socialProof,
                        viewModel.updateSocialProof,
                        helperText: "Témoignages, avis, statistiques",
                      ),
                    ],
                  ),

                  // Section: Paramètres Vidéo
                  _buildSectionHeader(colorScheme, "🎬 Paramètres Vidéo"),

                  ChipGroupSelector<Platform>(
                    label: "Plateforme",
                    options: Platform.values,
                    selectedValue: viewModel.selectedPlatform,
                    onSelected: viewModel.selectPlatform,
                    labelBuilder: (p) => VideoIdeaFormViewModel.platformLabels[p] ?? p.name,
                    colorScheme: colorScheme,
                  ),

                  ChipGroupSelector<DurationOption>(
                    label: "Durée",
                    options: DurationOption.values,
                    selectedValue: viewModel.selectedDuration,
                    onSelected: viewModel.selectDuration,
                    labelBuilder: (d) => VideoIdeaFormViewModel.durationLabels[d] ?? d.name,
                    colorScheme: colorScheme,
                  ),

                  ChipGroupSelector<VideoGoal>(
                    label: "Objectif",
                    options: VideoGoal.values,
                    selectedValue: viewModel.selectedGoal,
                    onSelected: viewModel.selectGoal,
                    labelBuilder: (g) => VideoIdeaFormViewModel.goalLabels[g] ?? g.name,
                    colorScheme: colorScheme,
                  ),

                  ChipGroupSelector<VideoTone>(
                    label: "Ton",
                    options: VideoTone.values,
                    selectedValue: viewModel.selectedTone,
                    onSelected: viewModel.selectTone,
                    labelBuilder: (t) => VideoIdeaFormViewModel.toneLabels[t] ?? t.name,
                    colorScheme: colorScheme,
                  ),

                  _buildInputGroup(
                    colorScheme,
                    "Bénéfices Clés ✨",
                    "Ex: Résultats en 7 jours, Sans produits chimiques, Garantie 30j",
                    viewModel.keyBenefits,
                    viewModel.updateKeyBenefits,
                    maxLines: 2,
                    helperText: "Séparés par des virgules - Listez 3-5 bénéfices principaux",
                  ),

                  _buildInputGroup(
                    colorScheme,
                    "Problème Résolu 🎯",
                    "Ex: Acné persistante, Fatigue chronique, Manque de temps",
                    viewModel.painPoint,
                    viewModel.updatePainPoint,
                    maxLines: 2,
                    helperText: "Quel problème votre produit résout-il ?",
                  ),

                  // Pricing Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monetization_on, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Tarification & Offre",
                              style: GoogleFonts.syne(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Prix",
                                    style: GoogleFonts.syne(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    onChanged: viewModel.updatePrice,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    controller: TextEditingController(text: viewModel.price)
                                      ..selection = TextSelection.collapsed(offset: viewModel.price.length),
                                    decoration: InputDecoration(
                                      hintText: "99.99 DT",
                                      prefixText: "💰 ",
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Offre Spéciale",
                                    style: GoogleFonts.syne(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    onChanged: viewModel.updateOffer,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    controller: TextEditingController(text: viewModel.offer)
                                      ..selection = TextSelection.collapsed(offset: viewModel.offer.length),
                                    decoration: InputDecoration(
                                      hintText: "-30%",
                                      prefixText: "🎁 ",
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Generation Mode Toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          Text(
                            viewModel.useRemoteGeneration ? '🤖' : '🏠',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.useRemoteGeneration
                                ? 'AI Generation (OpenAI)'
                                : 'Local Templates',
                              style: GoogleFonts.syne(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4, left: 28),
                        child: Text(
                          viewModel.useRemoteGeneration
                            ? 'Uses OpenAI to generate unique, creative ideas'
                            : 'Uses predefined templates for quick generation',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      value: viewModel.useRemoteGeneration,
                      onChanged: viewModel.toggleGenerationMode,
                      activeTrackColor: colorScheme.primary,
                      activeThumbColor: colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: viewModel.canGenerate()
                          ? () => _handleGenerate(context, viewModel)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(context.tr('generate_ideas')),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildInputGroup(
    ColorScheme colorScheme,
    String label,
    String hint,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    String? helperText,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged,
            maxLines: maxLines,
            maxLength: maxLength,
            style: TextStyle(color: colorScheme.onSurface),
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              counterText: maxLength != null ? null : '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroupWithSuggestions(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    String hint,
    String value,
    ValueChanged<String> onChanged,
    List<String> suggestions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged,
            style: TextStyle(color: colorScheme.onSurface),
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(5).map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: () => onChanged(suggestion),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(color: colorScheme.outlineVariant),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, VideoIdeaFormViewModel viewModel, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('smart_analysis'),
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (viewModel.isAnalyzing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('image_picker_desc'),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: viewModel.isAnalyzing ? null : () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      viewModel.updateProductImagePath(image.path);
                    }
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.tr('gallery')),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: viewModel.isAnalyzing ? null : () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      viewModel.updateProductImagePath(image.path);
                    }
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.tr('camera')),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (viewModel.productImagePath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.file(
                    File(viewModel.productImagePath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (viewModel.isAnalyzing)
                    Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('analyzing'),
                            style: GoogleFonts.syne(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: () => viewModel.updateProductImagePath(null),
                      icon: const Icon(Icons.close, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
