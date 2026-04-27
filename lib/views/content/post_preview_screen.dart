import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/plan.dart';

class PostPreviewScreen extends StatefulWidget {
  final ContentBlock block;
  final String brandName;

  const PostPreviewScreen({
    super.key,
    required this.block,
    required this.brandName,
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  String _selectedPlatform = 'instagram';

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
                      child: Icon(Icons.chevron_left_rounded,
                          size: 22, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Aperçu du Post',
                      style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                ],
              ),
            ),

            // Platform selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _platformBtn('instagram', '📸 Instagram', cs),
                    const SizedBox(width: 8),
                    _platformBtn('tiktok', '🎵 TikTok', cs),
                    const SizedBox(width: 8),
                    _platformBtn('facebook', '👥 Facebook', cs),
                  ],
                ),
              ),
            ),

            // Preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _selectedPlatform == 'instagram'
                    ? _buildInstagramPreview(cs)
                    : _selectedPlatform == 'tiktok'
                        ? _buildTikTokPreview(cs)
                        : _buildFacebookPreview(cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformBtn(String id, String label, ColorScheme cs) {
    final isSelected = _selectedPlatform == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlatform = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }

  // ── Instagram Preview ──────────────────────────────────────────────────────

  Widget _buildInstagramPreview(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    widget.brandName.isNotEmpty
                        ? widget.brandName[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.brandName.toLowerCase().replaceAll(' ', '_'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Sponsorisé',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey.shade700),
              ],
            ),
          ),

          // Image placeholder
          Container(
            height: 300,
            width: double.infinity,
            color: _formatColor(widget.block.format).withValues(alpha: 0.15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _formatIcon(widget.block.format),
                  size: 64,
                  color: _formatColor(widget.block.format),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.block.format.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _formatColor(widget.block.format),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, size: 26, color: Colors.black),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.black),
                const SizedBox(width: 14),
                const Icon(Icons.send_outlined, size: 24, color: Colors.black),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 26, color: Colors.black),
              ],
            ),
          ),

          // Likes
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '1 234 J\'aime',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${widget.brandName.toLowerCase().replaceAll(' ', '_')} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: widget.block.title),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Hashtags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _generateHashtags(),
              style: const TextStyle(
                color: Color(0xFF00376B),
                fontSize: 12,
              ),
            ),
          ),

          // CTA
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _ctaText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Time
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              'Il y a 2 heures',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TikTok Preview ─────────────────────────────────────────────────────────

  Widget _buildTikTokPreview(ColorScheme cs) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _formatColor(widget.block.format).withValues(alpha: 0.3),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Content icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _formatIcon(widget.block.format),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vidéo ${widget.block.format.label}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Right actions
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _tiktokAction(Icons.favorite, '12.4K'),
                const SizedBox(height: 20),
                _tiktokAction(Icons.chat_bubble, '234'),
                const SizedBox(height: 20),
                _tiktokAction(Icons.bookmark, '1.2K'),
                const SizedBox(height: 20),
                _tiktokAction(Icons.share, 'Partager'),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 12,
            right: 60,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.brandName.toLowerCase().replaceAll(' ', '_')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.block.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _generateHashtags(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tiktokAction(IconData icon, String label) => Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      );

  // ── Facebook Preview ───────────────────────────────────────────────────────

  Widget _buildFacebookPreview(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1877F2),
                  child: Text(
                    widget.brandName.isNotEmpty
                        ? widget.brandName[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.brandName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Sponsorisé · ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Icon(Icons.public,
                            size: 12, color: Colors.grey.shade600),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey.shade700),
              ],
            ),
          ),

          // Post text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.block.title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),

          // Image
          Container(
            height: 250,
            width: double.infinity,
            color: _formatColor(widget.block.format).withValues(alpha: 0.15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _formatIcon(widget.block.format),
                  size: 56,
                  color: _formatColor(widget.block.format),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.block.format.label,
                  style: TextStyle(
                    color: _formatColor(widget.block.format),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // CTA Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _ctaText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Reactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('👍❤️😮 ', style: TextStyle(fontSize: 14)),
                Text('1 234 réactions',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Text('56 commentaires',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade200),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _fbAction(Icons.thumb_up_outlined, 'J\'aime'),
                _fbAction(Icons.chat_bubble_outline, 'Commenter'),
                _fbAction(Icons.share_outlined, 'Partager'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _fbAction(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateHashtags() {
    final tags = [
      '#${widget.brandName.toLowerCase().replaceAll(' ', '')}',
      '#${widget.block.pillar.toLowerCase().replaceAll(' ', '')}',
      '#marketing',
      '#contenu',
      '#${widget.block.format.label.toLowerCase()}',
    ];
    return tags.join(' ');
  }

  String _ctaText() {
    switch (widget.block.ctaType) {
      case CtaType.hard:
        return 'Acheter maintenant →';
      case CtaType.soft:
        return 'En savoir plus →';
      case CtaType.educational:
        return 'Découvrir →';
    }
  }

  Color _formatColor(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:
        return const Color(0xFFE91E63);
      case ContentFormat.carousel:
        return const Color(0xFF2196F3);
      case ContentFormat.story:
        return const Color(0xFFFF9800);
      case ContentFormat.post:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _formatIcon(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:
        return Icons.play_circle_filled_rounded;
      case ContentFormat.carousel:
        return Icons.view_carousel_rounded;
      case ContentFormat.story:
        return Icons.auto_stories_rounded;
      case ContentFormat.post:
        return Icons.image_rounded;
    }
  }
}
