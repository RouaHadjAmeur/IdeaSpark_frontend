import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/plan.dart';
import '../../view_models/plan_view_model.dart';

class PhaseDetailScreen extends StatelessWidget {
  final Plan plan;
  final Phase phase;
  final int phaseIndex;

  const PhaseDetailScreen({
    super.key,
    required this.plan,
    required this.phase,
    required this.phaseIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = phase.status == PhaseStatus.terminated;
    final isActive = phase.status == PhaseStatus.inProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, cs, isDone, isActive),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhaseHeader(cs, isDone, isActive),
                  const SizedBox(height: 24),
                  Text(
                    'CONTENU DE LA PHASE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF9090B0),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContentBlocksList(context, cs),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ColorScheme cs, bool isDone, bool isActive) {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isActive ? const Color(0xFF6D4ED3) : const Color(0xFF1A1040),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          'Phase ${phaseIndex + 1}',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [const Color(0xFF6D4ED3), const Color(0xFF8B6FE8)]
                      : [const Color(0xFF1A1040), const Color(0xFF2D1B69)],
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                isActive ? Icons.bolt_rounded : Icons.auto_awesome_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseHeader(ColorScheme cs, bool isDone, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4ED3).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0EEFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDone 
                      ? const Color(0xFFE8FFF9) 
                      : (isActive ? const Color(0xFFF0EEFF) : const Color(0xFFEEE9FD)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  phase.status.name.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDone 
                        ? const Color(0xFF0EBFA1) 
                        : (isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0)),
                  ),
                ),
              ),
              Text(
                'Semaine ${phase.weekNumber}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFA89EC0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            phase.name,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1040),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phase.description ?? 'Optimisez votre visibilité avec une stratégie de contenu ciblée pour cette phase.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B5F85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildPhaseStat('Posts', phase.contentBlocks.length.toString(), Icons.grid_view_rounded),
              const SizedBox(width: 24),
              _buildPhaseStat('Format', 'Mixte', Icons.movie_filter_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFCFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF0EEFF)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF6D4ED3)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: const Color(0xFFA89EC0),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1040),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentBlocksList(BuildContext context, ColorScheme cs) {
    if (phase.contentBlocks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0EEFF)),
        ),
        child: Column(
          children: [
            const Icon(Icons.post_add_rounded, size: 48, color: Color(0xFFEEE9FD)),
            const SizedBox(height: 16),
            Text(
              'Aucun post prévu',
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA89EC0),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: phase.contentBlocks.length,
      itemBuilder: (context, index) {
        final block = phase.contentBlocks[index];
        return _buildContentBlockCard(context, block, index, cs);
      },
    );
  }

  Widget _buildContentBlockCard(BuildContext context, ContentBlock block, int index, ColorScheme cs) {
    final formatEmoji = {
      ContentFormat.reel: '🎬',
      ContentFormat.story: '📱',
      ContentFormat.post: '🖼️',
      ContentFormat.carousel: '🎠',
    }[block.format] ?? '📝';

    final statusColor = {
      ContentBlockStatus.draft: const Color(0xFFF59E0B),
      ContentBlockStatus.published: const Color(0xFF0EBFA1),
      ContentBlockStatus.scheduled: const Color(0xFF6D4ED3),
    }[block.status] ?? const Color(0xFFA89EC0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EEFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push('/content-block-detail', extra: {
            'plan': plan,
            'phase': phase,
            'block': block,
            'phaseIndex': phaseIndex,
            'blockIndex': index,
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(formatEmoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1A1040),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${block.format.name.toUpperCase()} • ${block.pillar}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: const Color(0xFFA89EC0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      block.status.name.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFEEE9FD)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
