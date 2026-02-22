import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AICampaignRoadmapScreen extends StatelessWidget {
  const AICampaignRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildWeekSection(
                    context,
                    'WEEK 1: AWARENESS & TEASING',
                    [
                      _RoadmapPost(type: 'Teaser', title: "The 'Big Reveal' Teaser", color: const Color(0xFF00D9FF)),
                      _RoadmapPost(type: 'Educational', title: 'Why STEM Matters Early', color: const Color(0xFF6BCB77)),
                      _RoadmapPost(type: 'Teaser', title: 'Check your Inbox at 6PM', color: const Color(0xFF00D9FF)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildWeekSection(
                    context,
                    'WEEK 2: INTEREST & VALUE',
                    [
                      _RoadmapPost(type: 'Launch', title: 'Fort Kit is officially LIVE!', color: const Color(0xFFFF3D71)),
                      _RoadmapPost(type: 'Objection', title: 'Is it too hard to build?', color: const Color(0xFFFFD93D)),
                      _RoadmapPost(type: 'Social Proof', title: 'First 50 orders are in!', color: const Color(0xFF00FF88)),
                    ],
                  ),
                ],
              ),
            ),
            _buildStickyCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Campaign Roadmap',
              style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded, size: 20, color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "AI-optimized for 'Fort Kit Launch'",
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildWeekSection(BuildContext context, String label, List<_RoadmapPost> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...posts,
      ],
    );
  }

  Widget _buildStickyCTA(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withOpacity(0),
              colorScheme.surface.withOpacity(0.9),
              colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'REGENERATE',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'ADD TO CALENDAR',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapPost extends StatelessWidget {
  final String type;
  final String title;
  final Color color;

  const _RoadmapPost({required this.type, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 1),
                ),
                const SizedBox(height: 3),
                Text(title, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
              ],
            ),
          ),
          Row(
            children: [
              _ActionButton(icon: Icons.edit_outlined),
              const SizedBox(width: 6),
              _ActionButton(icon: Icons.delete_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  const _ActionButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
    );
  }
}
