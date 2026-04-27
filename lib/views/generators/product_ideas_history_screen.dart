import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_idea_model.dart';
import '../../view_models/product_idea_view_model.dart';
import '../../widgets/loading_widget.dart';


class ProductIdeasHistoryScreen extends StatefulWidget {
  const ProductIdeasHistoryScreen({super.key});

  @override
  State<ProductIdeasHistoryScreen> createState() => _ProductIdeasHistoryScreenState();
}

class _ProductIdeasHistoryScreenState extends State<ProductIdeasHistoryScreen> {
  late ProductIdeaViewModel _viewModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductIdeaViewModel();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _viewModel.loadSavedIdeas();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Mes Idées Produits',
          style: GoogleFonts.syne(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _viewModel.savedIdeas.isEmpty
              ? _buildEmptyState(colorScheme)
              : Column(
                  children: [
                    _buildStats(colorScheme),
                    const SizedBox(height: 20),
                    Expanded(child: _buildIdeasList(colorScheme)),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
          '/product-ideas-form',
          (route) => false,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle idée'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 50,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune idée sauvegardée',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez par générer votre première idée produit\net sauvegardez-la pour la retrouver ici',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/product-ideas-form',
              (route) => false,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer ma première idée'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            colorScheme,
            '${_viewModel.savedIdeas.length}',
            'Total',
            Icons.lightbulb_rounded,
          ),
          Container(
            width: 1,
            height: 50,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          _buildStatItem(
            colorScheme,
            '${_viewModel.savedIdeas.where((idea) => idea.isFavorite).length}',
            'Favoris',
            Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ColorScheme colorScheme, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.syne(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildIdeasList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Padding bottom pour FAB
      itemCount: _viewModel.savedIdeas.length,
      itemBuilder: (context, index) {
        final idea = _viewModel.savedIdeas[index];
        return _IdeaCard(
          idea: idea,
          colorScheme: colorScheme,
          onTap: () => _showIdeaDetails(idea),
          onDelete: () => _deleteIdea(idea),
          onToggleFavorite: () => _toggleFavorite(idea),
        );
      },
    );
  }

  void _showIdeaDetails(SavedProductIdea idea) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _IdeaDetailsScreen(idea: idea),
      ),
    );
  }

  Future<void> _deleteIdea(SavedProductIdea idea) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    await _viewModel.deleteIdea(idea.id!);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Idée supprimée avec succès'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer cette idée ?'),
        content: Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _toggleFavorite(SavedProductIdea idea) async {
    await _viewModel.toggleFavorite(idea.id!);
  }
}

class _IdeaCard extends StatelessWidget {
  final SavedProductIdea idea;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _IdeaCard({
    required this.idea,
    required this.colorScheme,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: idea.isFavorite 
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: idea.isFavorite 
                            ? colorScheme.primary.withOpacity(0.1)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        size: 20,
                        color: idea.isFavorite 
                            ? colorScheme.primary 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idea.produit.nomDuProduit,
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(idea.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        idea.isFavorite 
                            ? Icons.star_rounded 
                            : Icons.star_outline_rounded,
                        color: idea.isFavorite 
                            ? colorScheme.primary 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  idea.besoin,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildChip(
                              colorScheme,
                              Icons.person_outline_rounded,
                              _truncateText(idea.produit.cible, 20),
                            ),
                            const SizedBox(width: 8),
                            _buildChip(
                              colorScheme,
                              Icons.work_outline_rounded,
                              'Produit',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ColorScheme colorScheme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _IdeaDetailsScreen extends StatefulWidget {
  final SavedProductIdea idea;

  const _IdeaDetailsScreen({required this.idea});

  @override
  State<_IdeaDetailsScreen> createState() => _IdeaDetailsScreenState();
}

class _IdeaDetailsScreenState extends State<_IdeaDetailsScreen> {
  late TextEditingController _besoinController;
  late TextEditingController _nomProduitController;
  late TextEditingController _problemeController;
  late TextEditingController _solutionController;
  late TextEditingController _cibleController;
  late TextEditingController _modeleEconomiqueController;
  late TextEditingController _mvpController;
  
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _besoinController = TextEditingController(text: widget.idea.besoin);
    _nomProduitController = TextEditingController(text: widget.idea.produit.nomDuProduit);
    _problemeController = TextEditingController(text: widget.idea.produit.probleme);
    _solutionController = TextEditingController(text: widget.idea.produit.solution);
    _cibleController = TextEditingController(text: widget.idea.produit.cible);
    _modeleEconomiqueController = TextEditingController(text: widget.idea.produit.modeleEconomique);
    _mvpController = TextEditingController(text: widget.idea.produit.mvp);
  }

  @override
  void dispose() {
    _besoinController.dispose();
    _nomProduitController.dispose();
    _problemeController.dispose();
    _solutionController.dispose();
    _cibleController.dispose();
    _modeleEconomiqueController.dispose();
    _mvpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.surface.withOpacity(0.8),
                                  foregroundColor: colorScheme.onSurface,
                                ),
                              ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.share_rounded, color: colorScheme.onSurface),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.surface.withOpacity(0.8),
                                foregroundColor: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Détails de l\'idée',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildHeroSection(colorScheme),
                  const SizedBox(height: 32),
                  _buildQuickInfo(colorScheme),
                  const SizedBox(height: 32),
                  _buildEditableSection(colorScheme, 'Besoin identifié', _besoinController, Icons.help_outline_rounded),
                  const SizedBox(height: 24),
                  _buildEditableSection(colorScheme, 'Nom du produit', _nomProduitController, Icons.lightbulb_rounded),
                  const SizedBox(height: 24),
                  _buildEditableProblemSolutionSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildEditableTargetSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildEditableBusinessModelSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildEditableMVPSection(colorScheme),
                  const SizedBox(height: 32),
                  _buildActionsSection(colorScheme),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.idea.produit.nomDuProduit,
                      style: GoogleFonts.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (widget.idea.isFavorite) ...[
                          Icon(
                            Icons.star_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Favori',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Produit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  colorScheme,
                  Icons.schedule_rounded,
                  'Date',
                  _formatDate(widget.idea.createdAt),
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  colorScheme,
                  Icons.timer_rounded,
                  'Génération',
                  '${widget.idea.durationSeconds}s',
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  colorScheme,
                  Icons.person_outline_rounded,
                  'Cible',
                  widget.idea.produit.cible,
                  colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  colorScheme,
                  Icons.favorite_rounded,
                  'Statut',
                  widget.idea.isFavorite ? 'Favori' : 'Normal',
                  widget.idea.isFavorite ? colorScheme.error : colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSection(ColorScheme colorScheme, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(ColorScheme colorScheme, String title, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isEditing ? colorScheme.primary.withOpacity(0.3) : colorScheme.outline.withOpacity(0.1),
          width: _isEditing ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isEditing ? colorScheme.primary.withOpacity(0.1) : colorScheme.shadow.withOpacity(0.05),
            blurRadius: _isEditing ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEditing ? colorScheme.primary.withOpacity(0.2) : colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: _isEditing ? colorScheme.primary : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Édition',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextField(
                  controller: controller,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    fillColor: colorScheme.surfaceContainerHighest,
                    filled: true,
                  ),
                )
              : Text(
                  controller.text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEditableProblemSolutionSection(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildEditableSection(colorScheme, 'Problème résolu', _problemeController, Icons.error_outline_rounded),
        const SizedBox(height: 16),
        _buildEditableSection(colorScheme, 'Solution proposée', _solutionController, Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _buildEditableTargetSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiary.withOpacity(0.1),
            colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isEditing ? colorScheme.tertiary.withOpacity(0.4) : colorScheme.tertiary.withOpacity(0.2),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEditing ? colorScheme.tertiary.withOpacity(0.3) : colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cible',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextField(
                  controller: _cibleController,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.tertiary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.tertiary),
                    ),
                    fillColor: colorScheme.surface,
                    filled: true,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _cibleController.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEditableBusinessModelSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isEditing ? colorScheme.secondary.withOpacity(0.4) : colorScheme.secondary.withOpacity(0.2),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEditing ? colorScheme.secondary.withOpacity(0.3) : colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  size: 20,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Modèle économique',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextField(
                  controller: _modeleEconomiqueController,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.secondary),
                    ),
                    fillColor: colorScheme.surface,
                    filled: true,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _modeleEconomiqueController.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEditableMVPSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isEditing ? colorScheme.error.withOpacity(0.4) : colorScheme.error.withOpacity(0.2),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEditing ? colorScheme.error.withOpacity(0.3) : colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MVP (Produit Minimum Viable)',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextField(
                  controller: _mvpController,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.error.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.error),
                    ),
                    fillColor: colorScheme.surface,
                    filled: true,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _mvpController.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProblemSolutionSection(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildDetailedSection(colorScheme, '❌ Problème résolu', widget.idea.produit.probleme, Icons.error_outline_rounded),
        const SizedBox(height: 16),
        _buildDetailedSection(colorScheme, '✅ Solution proposée', widget.idea.produit.solution, Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _buildTargetSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiary.withOpacity(0.1),
            colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🎯 Cible',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.idea.produit.cible,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessModelSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  size: 20,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '💶 Modèle économique',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.idea.produit.modeleEconomique,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMVPSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🧪 MVP (Produit Minimum Viable)',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.idea.produit.mvp,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? FilledButton.icon(
                        onPressed: _isSaving ? null : _saveChanges,
                        icon: _isSaving 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Modifier'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isEditing
                    ? OutlinedButton.icon(
                        onPressed: () => _cancelEditing(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(color: colorScheme.outline),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Partager'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(color: colorScheme.outline),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteIdea,
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
              label: Text('Supprimer', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _initializeControllers(); // Réinitialiser les valeurs originales
    });
  }

  Future<void> _saveChanges() async {
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isSaving = true);

    try {
      // Créer un objet mis à jour
      final updatedIdea = widget.idea.copyWith(
        besoin: _besoinController.text,
        produit: widget.idea.produit.copyWith(
          nomDuProduit: _nomProduitController.text,
          probleme: _problemeController.text,
          solution: _solutionController.text,
          cible: _cibleController.text,
          modeleEconomique: _modeleEconomiqueController.text,
          mvp: _mvpController.text,
        ),
      );

      // TODO: Appeler le service pour mettre à jour dans la base de données
      // await ProductIdeaService.updateProductIdea(widget.idea.id!, updatedIdea);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modifications enregistrées avec succès !'),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteIdea() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer cette idée ?'),
        content: Text('Cette action est irréversible et supprimera définitivement cette idée produit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: Appeler le service pour supprimer
      // await ProductIdeaService.deleteProductIdea(widget.idea.id!);

      if (mounted) {
        Navigator.of(context).pop(); // Retour à la liste
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Idée supprimée avec succès'),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildMetadata(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Créé le: ${widget.idea.createdAt?.day}/${widget.idea.createdAt?.month}/${widget.idea.createdAt?.year}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_rounded, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Durée de génération: ${widget.idea.durationSeconds}s',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
