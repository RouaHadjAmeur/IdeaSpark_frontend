import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/scheduled_post.dart';
import '../../services/advanced_share_service.dart';
import '../../services/instagram_insights_service.dart';

class AdvancedShareScreen extends StatefulWidget {
  final String contentUrl;
  final String contentType; // 'image' ou 'video'
  final String? contentId;

  const AdvancedShareScreen({
    super.key,
    required this.contentUrl,
    required this.contentType,
    this.contentId,
  });

  @override
  State<AdvancedShareScreen> createState() => _AdvancedShareScreenState();
}

class _AdvancedShareScreenState extends State<AdvancedShareScreen> {
  final _captionController = TextEditingController();
  final _hashtagsController = TextEditingController();
  
  List<SocialPlatform> _selectedPlatforms = [];
  List<SocialAccount> _connectedAccounts = [];
  List<String> _selectedAccountIds = [];
  List<String> _generatedHashtags = [];
  
  DateTime? _scheduledDateTime;
  bool _isScheduled = false;
  bool _isLoading = false;
  bool _isGeneratingHashtags = false;
  bool _isLoadingAudio = false;
  List<TrendingAudioItem> _trendingAudios = [];
  String? _selectedAudioUrl;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
    _loadTrendingAudios();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedAccounts() async {
    setState(() => _isLoading = true);
    
    try {
      final accounts = await AdvancedShareService.getConnectedAccounts();
      setState(() {
        _connectedAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTrendingAudios() async {
    setState(() => _isLoadingAudio = true);
    try {
      final audios = await InstagramInsightsService().fetchTrendingAudio();
      setState(() {
        _trendingAudios = audios;
        _isLoadingAudio = false;
      });
    } catch (e) {
      setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _generateHashtags() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord une légende')),
      );
      return;
    }

    setState(() => _isGeneratingHashtags = true);

    try {
      final hashtags = await AdvancedShareService.generateHashtags(
        content: _captionController.text.trim(),
        category: 'lifestyle', // Détection automatique dans le service
        maxHashtags: 10,
      );

      setState(() {
        _generatedHashtags = hashtags;
        _hashtagsController.text = hashtags.join(' ');
        _isGeneratingHashtags = false;
      });
    } catch (e) {
      setState(() => _isGeneratingHashtags = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur génération hashtags: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareContent() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez une légende')),
      );
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une plateforme')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hashtags = _hashtagsController.text
          .split(' ')
          .where((tag) => tag.trim().isNotEmpty)
          .toList();

      if (_isScheduled && _scheduledDateTime != null) {
        // Programmer la publication
        await AdvancedShareService.schedulePost(
          contentId: widget.contentId ?? '',
          contentType: widget.contentType,
          contentUrl: widget.contentUrl,
          caption: _captionController.text.trim(),
          hashtags: hashtags,
          platforms: _selectedPlatforms,
          accountIds: _selectedAccountIds,
          scheduledTime: _scheduledDateTime!,
          audioUrl: _selectedAudioUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Publication programmée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Partager immédiatement
        await AdvancedShareService.shareWithCaption(
          contentUrl: widget.contentUrl,
          caption: _captionController.text.trim(),
          platforms: _selectedPlatforms,
          accountIds: _selectedAccountIds,
          audioUrl: _selectedAudioUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Contenu partagé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cs),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aperçu du contenu
                    _buildContentPreview(cs),
                    
                    const SizedBox(height: 24),
                    
                    // Légende
                    _buildCaptionSection(cs),
                    
                    const SizedBox(height: 24),
                    
                    // Hashtags
                    _buildHashtagsSection(cs),
                    
                    const SizedBox(height: 24),
                    
                    // Plateformes
                    _buildPlatformsSection(cs),
                    
                    const SizedBox(height: 24),

                    // Trending Audio
                    if (widget.contentType == 'video' || widget.contentType == 'image') ...[
                      _buildAudioSection(cs),
                      const SizedBox(height: 24),
                    ],
                    
                    // Comptes
                    _buildAccountsSection(cs),
                    
                    const SizedBox(height: 24),
                    
                    // Programmation
                    _buildSchedulingSection(cs),
                    
                    const SizedBox(height: 100), // Espace pour les boutons
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            _buildActionButtons(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              child: Icon(Icons.chevron_left_rounded, size: 22, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partage Avancé',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Programmation et multi-comptes',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(ColorScheme cs) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.contentType == 'image'
            ? Image.network(
                widget.contentUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Center(
                  child: Icon(Icons.error_outline, size: 48, color: cs.error),
                ),
              )
            : Container(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: cs.onSurface,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCaptionSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Légende',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Écrivez votre légende...',
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hashtags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isGeneratingHashtags ? null : _generateHashtags,
              icon: _isGeneratingHashtags
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Générer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hashtagsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '#hashtag1 #hashtag2 #hashtag3...',
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_generatedHashtags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _generatedHashtags.map((hashtag) {
              return Chip(
                label: Text(hashtag, style: const TextStyle(fontSize: 12)),
                backgroundColor: cs.primaryContainer,
                labelStyle: TextStyle(color: cs.onPrimaryContainer),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plateformes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SocialPlatform.values.map((platform) {
            final isSelected = _selectedPlatforms.contains(platform);
            
            return FilterChip(
              label: Text(_getPlatformLabel(platform)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPlatforms.add(platform);
                  } else {
                    _selectedPlatforms.remove(platform);
                  }
                });
              },
              avatar: Icon(
                _getPlatformIcon(platform),
                size: 16,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(ColorScheme cs) {
    final availableAccounts = _connectedAccounts
        .where((account) => _selectedPlatforms.contains(account.platform))
        .toList();

    if (availableAccounts.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comptes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...availableAccounts.map((account) {
          final isSelected = _selectedAccountIds.contains(account.id);
          
          return CheckboxListTile(
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedAccountIds.add(account.id);
                } else {
                  _selectedAccountIds.remove(account.id);
                }
              });
            },
            title: Text(account.name),
            subtitle: Text('@${account.username}'),
            secondary: CircleAvatar(
              backgroundImage: account.profileImageUrl != null
                  ? NetworkImage(account.profileImageUrl!)
                  : null,
              child: account.profileImageUrl == null
                  ? Icon(_getPlatformIcon(account.platform))
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSchedulingSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Programmation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isScheduled,
              onChanged: (value) => setState(() => _isScheduled = value),
            ),
          ],
        ),
        if (_isScheduled) ...[
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.schedule, color: cs.primary),
            title: Text(_scheduledDateTime != null
                ? DateFormat('dd/MM/yyyy à HH:mm').format(_scheduledDateTime!)
                : 'Sélectionner date et heure'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectDateTime,
            tileColor: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _shareContent,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isScheduled ? Icons.schedule : Icons.share, size: 18),
              label: Text(_isScheduled ? 'Programmer' : 'Partager'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Musique (Trending Audio)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        if (widget.contentType == 'image') ...[
          const SizedBox(height: 4),
          Text(
            'L\'image sera convertie en vidéo pour inclure la musique.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoadingAudio)
          const Center(child: CircularProgressIndicator())
        else if (_trendingAudios.isEmpty)
          Text('Aucune musique disponible', style: TextStyle(color: cs.onSurfaceVariant))
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _trendingAudios.length,
              itemBuilder: (context, index) {
                final audio = _trendingAudios[index];
                final audioUrl = audio.previewUrl ?? '';
                final isSelected = _selectedAudioUrl == audioUrl;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAudioUrl = null;
                      } else {
                        _selectedAudioUrl = audioUrl;
                      }
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                audio.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          audio.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? cs.primary : cs.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getPlatformLabel(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.youtube:
        return 'YouTube';
    }
  }

  IconData _getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.tiktok:
        return Icons.music_video;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.twitter:
        return Icons.alternate_email;
      case SocialPlatform.linkedin:
        return Icons.business;
      case SocialPlatform.youtube:
        return Icons.play_circle;
    }
  }
}