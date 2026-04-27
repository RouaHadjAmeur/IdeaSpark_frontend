import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_localizations.dart';
import '../../models/plan.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../models/brand.dart';

class CampaignManagerHubScreen extends StatefulWidget {
  final Plan? plan;
  const CampaignManagerHubScreen({super.key, this.plan});

  @override
  State<CampaignManagerHubScreen> createState() => _CampaignManagerHubScreenState();
}

class _CampaignManagerHubScreenState extends State<CampaignManagerHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Plan? _activePlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _activePlan = widget.plan;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final pvm = context.read<PlanViewModel>();
    await pvm.loadPlans();
    if (_activePlan == null && pvm.plans.isNotEmpty) {
      // Pick the first active plan or the most recent one
      setState(() {
        _activePlan = pvm.plans.firstWhere(
          (p) => p.status == PlanStatus.active,
          orElse: () => pvm.plans.first,
        );
      });
    }
    
    if (_activePlan != null) {
      await pvm.loadAIInsights(_activePlan!.id!);
      if (mounted) {
        context.read<CollaborationViewModel>().loadActivityLog(_activePlan!.id!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (_activePlan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('nav_campaign_manager'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(cs),
            _buildCustomTabBar(cs),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDecisionsTab(cs),
                  _buildAutomationTab(cs),
                  _buildJournalTab(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stratégie Automatisée',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1.0),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          builder: (context, val, child) {
                            return Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: val * 0.5),
                                    blurRadius: 10 * val,
                                    spreadRadius: 2 * val,
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Campaign Manager',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Actif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Performance Snapshot
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '94%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                          fontFamily: 'Space Mono',
                        ),
                      ),
                      Text(
                        'DNA Score IA',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '2.8x',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                          fontFamily: 'Space Mono',
                        ),
                      ),
                      Text(
                        'ROI Actuel',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: cs.primary,
        indicatorWeight: 3,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: '🤖 ${context.tr('hub_decisions')}'),
          Tab(text: '⚙ ${context.tr('hub_automation')}'),
          Tab(text: '📋 ${context.tr('hub_journal')}'),
        ],
      ),
    );
  }

  Widget _buildDecisionsTab(ColorScheme cs) {
    final pvm = context.watch<PlanViewModel>();
    final insights = pvm.aiInsights;
    final readiness = _activePlan!.projectDNA.performance.readinessScore;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPerformanceHeader(cs, readiness, insights),
        const SizedBox(height: 20),
        Text(
          'ACTIONS EN ATTENTE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildPendingActions(cs, insights),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPerformanceHeader(ColorScheme cs, int score, Map<String, dynamic> insights) {
    final brandVm = context.watch<BrandViewModel>();
    final brand = brandVm.brands.firstWhere(
      (b) => b.id == _activePlan!.brandId,
      orElse: () => Brand(
        name: 'Brand associated',
        tone: BrandTone.professional,
        audience: BrandAudience(ageRange: '', gender: '', interests: []),
        platforms: [],
        contentPillars: []
      )
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10082A), cs.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 8),
              const SizedBox(width: 8),
              Text(
                'Campaign Manager · Actif'.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _activePlan!.name,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Syne', fontWeight: FontWeight.w800),
          ),
          Text(
            '${brand.name} · Sem. 3/8',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreItem('94%', 'DNA Score'),
              _buildScoreItem('2.8×', 'ROI actuel'),
              _buildScoreItem('82', 'Score global'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildPendingActions(ColorScheme cs, Map<String, dynamic> insights) {
    final List recs = insights['recommendations'] ?? [
      'Live Instagram — Lundi 20h. 3 200 abonnés notifiés. Contenu non finalisé.',
      'Capitaliser le pic TikTok. Ton teaser a généré +38% de portée. Publie vendredi 19h.',
      'Avancer le challenge UGC. Lancer le challenge 2 semaines plus tôt augmenterait l\'impact de +22%.',
    ];

    return recs.asMap().entries.map((entry) {
      final idx = entry.key;
      final text = entry.value.toString();
      final isUrgent = idx == 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent ? cs.errorContainer.withValues(alpha: 0.1) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent ? cs.error.withValues(alpha: 0.2) : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: (isUrgent ? cs.error : cs.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUrgent ? Icons.priority_high_rounded : Icons.lightbulb_outline_rounded,
                    color: isUrgent ? cs.error : cs.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idx == 0 ? 'LIVE INSTAGRAM — LUNDI 20H' : (idx == 1 ? 'CAPITALISER LE PIC TIKTOK' : 'AVANCER LE CHALLENGE UGC'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Syne'),
                      ),
                      Text(
                        isUrgent ? 'Urgent · Milestone Phase 2' : 'Opportunité · Stratégie',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isUrgent ? cs.error : cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: isUrgent ? cs.error : cs.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('✓ Confirmer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Voir Détails', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () {},
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAutomationTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'ACTIONS AUTOMATIQUES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildAutomationToggle(cs, 'Optimisation du timing', 'Repositionne vers jeu-ven 19h auto', Icons.timer_outlined, true),
        _buildAutomationToggle(cs, 'Rapport hebdomadaire IA', 'Envoi chaque lundi à 8h00', Icons.analytics_outlined, true),
        _buildAutomationToggle(cs, 'Recyclage contenu viral', 'Propose de republier les best posts', Icons.recycling_rounded, true),
        _buildAutomationToggle(cs, 'Alertes deadline', 'Notification 48h avant chaque pub.', Icons.notifications_active_outlined, true),
        _buildAutomationToggle(cs, 'DM de bienvenue', 'Message auto nouveaux abonnés', Icons.chat_bubble_outline_rounded, false),
        
        const SizedBox(height: 24),
        Text(
          'CAMPAGNES MAILING',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildMailCard(cs, 'Newsletter Lancement · Stratégie', 'Active', '44%', '9.1%', '2800'),
        _buildMailCard(cs, 'Offre Early Bird — Premium', 'Brouillon', '-', '-', '-'),
        
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: const Text('Créer campagne mailing'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            foregroundColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAutomationToggle(ColorScheme cs, String title, String sub, IconData icon, bool initialValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(sub, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(value: initialValue, onChanged: (v) {}),
        ],
      ),
    );
  }

  Widget _buildMailCard(ColorScheme cs, String title, String status, String openRate, String clickRate, String sent) {
    final isActive = status == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? Colors.green : Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMailStat('Ouv.', openRate),
              const SizedBox(width: 16),
              _buildMailStat('Clics', clickRate),
              const SizedBox(width: 16),
              _buildMailStat('Envoyés', sent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMailStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildJournalTab(ColorScheme cs) {
    final cvm = context.watch<CollaborationViewModel>();
    final authVm = context.watch<AuthViewModel>();
    String userName = 'User';
    if (authVm.currentUser?.displayName != null) {
      userName = authVm.currentUser?.displayName ?? 'User';
    } else if (authVm.currentUser?.email != null) {
      final email = authVm.currentUser?.email;
      if (email != null) {
        userName = email.split('@')[0];
      }
    }
    
    final logs = cvm.activityLog.isNotEmpty ? cvm.activityLog : [
      {'actionType': '✅', 'userName': 'Publication TikTok optimisée', 'fieldChanged': 'Post déplacé 14h → 19h30 (créneau optimal)', 'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), 'user': userName},
      {'actionType': '📊', 'userName': 'Score DNA recalculé', 'fieldChanged': '94% → +3 pts suite ajout Story sondage', 'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(), 'user': userName},
      {'actionType': '🔔', 'userName': 'Alerte deadline envoyée', 'fieldChanged': 'Sara A. et Karim M. notifiés — Carrousel 25 avr', 'createdAt': DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(), 'user': userName},
      {'actionType': '📈', 'userName': 'Tendance #AItools détectée', 'fieldChanged': '+240% en 24h sur TikTok · 3 idées générées', 'createdAt': DateTime.now().subtract(const Duration(hours: 32)).toIso8601String(), 'user': userName},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'JOURNAL IA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final idx = entry.key;
              final log = entry.value;
              return _buildJournalItem(cs, log, idx == logs.length - 1);
            }).toList(),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildJournalItem(ColorScheme cs, dynamic log, bool isLast) {
    final actionType = log['actionType']?.toString() ?? '🤖';
    final title = log['userName']?.toString() ?? '';
    final desc = log['fieldChanged']?.toString() ?? '';
    final timeStr = log['createdAt'] != null ? _formatLogTime(log['createdAt']) : '';
    final user = log['user']?.toString() ?? 'User';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(actionType, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Syne')),
                Text('$user · collaborator', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.4)),
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLogTime(String iso) {
    final dt = DateTime.parse(iso);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) {
      if (diff.inHours == 0) return 'Il y a ${diff.inMinutes} min';
      return 'Il y a ${diff.inHours}h';
    }
    return DateFormat('dd MMM, HH:mm').format(dt);
  }
}
