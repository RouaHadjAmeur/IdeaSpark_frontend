import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/plan.dart';
import '../../services/caption_generator_service.dart';
import '../../services/trending_hashtags_service.dart';

class CaptionGeneratorScreen extends StatefulWidget {
  final ContentBlock block;
  final String brandName;

  const CaptionGeneratorScreen({
    super.key,
    required this.block,
    required this.brandName,
  });

  @override
  State<CaptionGeneratorScreen> createState() => _CaptionGeneratorScreenState();
}

class _CaptionGeneratorScreenState extends State<CaptionGeneratorScreen> {
  String _selectedPlatform = 'Instagram';
  bool _isLoading = false;
  bool _isLoadingHashtags = false;
  CaptionResult? _result;
  String? _error;
  int _selectedCaption = 1; // 0=short, 1=medium, 2=long
  List<String> _trendingHashtags = [];

  final _platforms = ['Instagram', 'TikTok', 'Facebook', 'LinkedIn'];
  final _service = CaptionGeneratorService();

  Future<void> _generate() async {
    setState(() { _isLoading = true; _error = null; _result = null; });
    await Future.delayed(const Duration(milliseconds: 500)); // simulate loading
    final result = _service.generate(
      postTitle: widget.block.title,
      platform: _selectedPlatform,
      format: widget.block.format,
      pillar: widget.block.pillar,
      ctaType: widget.block.ctaType,
      brandName: widget.brandName,
    );
    if (mounted) setState(() { _result = result; _isLoading = false; });
  }

  Future<void> _loadTrendingHashtags() async {
    setState(() => _isLoadingHashtags = true);
    
    try {
      // Détecter la catégorie (vous pouvez passer la description de la marque si disponible)
      final category = TrendingHashtagsService.detectCategory(widget.block.pillar);
      
      final hashtags = await TrendingHashtagsService.generateHashtags(
        brandName: widget.brandName,
        postTitle: widget.block.title,
        category: category,
        platform: _selectedPlatform.toLowerCase(),
      );
      
      if (mounted) {
        setState(() {
          _trendingHashtags = hashtags;
          _isLoadingHashtags = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${hashtags.length} hashtags tendances ajoutés !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHashtags = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Caption copiée !'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
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
                      width: 34, height: 34,
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
                        Text('Générateur de Captions',
                            style: GoogleFonts.syne(
                                fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        Text(widget.block.title,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
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
                    // Post info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(widget.block.format.label,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(widget.block.title,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Platform selector
                    Text('Plateforme',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _platforms.map((p) {
                          final isSelected = _selectedPlatform == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPlatform = p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? cs.primary : cs.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  '${_platformEmoji(p)} $p',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? cs.onPrimary : cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _generate,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(_isLoading ? 'Génération en cours...' : '✨ Générer les Captions'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Trending Hashtags button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingHashtags ? null : _loadTrendingHashtags,
                        icon: _isLoadingHashtags
                            ? SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.primary))
                            : const Icon(Icons.trending_up, size: 20),
                        label: Text(_isLoadingHashtags 
                            ? 'Chargement...' 
                            : '🔥 Hashtags Tendances'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: cs.primary),
                        ),
                      ),
                    ),

                    // Results
                    if (_result != null) ...[
                      const SizedBox(height: 24),

                      // Caption length selector
                      Row(children: [
                        _captionTab(0, 'Courte', cs),
                        const SizedBox(width: 8),
                        _captionTab(1, 'Moyenne', cs),
                        const SizedBox(width: 8),
                        _captionTab(2, 'Longue', cs),
                      ]),
                      const SizedBox(height: 12),

                      // Caption text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Caption',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _copyToClipboard(_getCaptionText()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.copy, size: 14, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text('Copier',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            SelectableText(
                              _getCaptionText(),
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurface, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hashtags
                      Text('Hashtags',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _result!.hashtags.map((h) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(h,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4285F4),
                                        fontWeight: FontWeight.w500)),
                              )).toList(),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _copyToClipboard(_result!.hashtags.join(' ')),
                              child: Row(children: [
                                Icon(Icons.copy, size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text('Copier tous les hashtags',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.primary,
                                        fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      
                      // Trending Hashtags section
                      if (_trendingHashtags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Icon(Icons.trending_up, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text('Hashtags Tendances',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _trendingHashtags.map((h) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department, 
                                          size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(h,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )).toList(),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _copyToClipboard(_trendingHashtags.join(' ')),
                                child: Row(children: [
                                  const Icon(Icons.copy, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  const Text('Copier tous les hashtags tendances',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Emojis
                      Text('Emojis suggérés',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: _result!.emojis.map((e) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _copyToClipboard(e),
                              child: Text(e, style: const TextStyle(fontSize: 28)),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA
                      Text('Call to Action',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(_result!.cta,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          GestureDetector(
                            onTap: () => _copyToClipboard(_result!.cta),
                            child: Icon(Icons.copy, size: 18, color: Colors.orange.shade700),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // Copy all button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final allHashtags = [
                              ..._result!.hashtags,
                              ..._trendingHashtags,
                            ].join(' ');
                            _copyToClipboard(
                              '${_getCaptionText()}\n\n$allHashtags',
                            );
                          },
                          icon: const Icon(Icons.copy_all),
                          label: Text(_trendingHashtags.isEmpty 
                              ? 'Copier Caption + Hashtags'
                              : 'Copier Caption + Tous les Hashtags'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captionTab(int index, String label, ColorScheme cs) {
    final isSelected = _selectedCaption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCaption = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onPrimary : cs.onSurface)),
      ),
    );
  }

  String _getCaptionText() {
    if (_result == null) return '';
    switch (_selectedCaption) {
      case 0: return _result!.short;
      case 2: return _result!.long;
      default: return _result!.medium;
    }
  }

  String _platformEmoji(String p) {
    switch (p) {
      case 'Instagram': return '📸';
      case 'TikTok': return '🎵';
      case 'Facebook': return '👥';
      case 'LinkedIn': return '💼';
      default: return '📱';
    }
  }
}
