import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentFullAccessScreen extends StatefulWidget {
  const AgentFullAccessScreen({super.key});

  @override
  State<AgentFullAccessScreen> createState() => _AgentFullAccessScreenState();
}

class _AgentFullAccessScreenState extends State<AgentFullAccessScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isProcessing = false;
  bool _showResults = false;

  final List<Map<String, String>> _agents = [
    {
      'name': 'Video Agent',
      'icon': '🎬',
      'prompt': 'Générer 3 scripts de vidéos courtes basés sur l\'idée principale.',
    },
    {
      'name': 'Slogan Agent',
      'icon': '✍️',
      'prompt': 'Créer 5 slogans percutants et mémorables.',
    },
    {
      'name': 'Product Agent',
      'icon': '🚀',
      'prompt': 'Définir les caractéristiques clés du produit et son positionnement.',
    },
  ];

  void _processPrompt() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _showResults = false;
    });

    // Simulation d'un traitement IA
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _showResults = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agent Full Access',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(colorScheme),
            const SizedBox(height: 24),
            Text(
              'Votre Prompt Principal',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Décrivez votre vision globale ici...',
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPrompt,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Analyser & Déléguer'),
              ),
            ),
            if (_showResults) ...[
              const SizedBox(height: 32),
              Text(
                'Délégation aux Agents IA',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ..._agents.map((agent) => _buildAgentPromptCard(agent, colorScheme)),
              const SizedBox(height: 32),
              _buildFinalPlanCard(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cet agent possède un accès complet à tous les moteurs IA de l\'application pour orchestrer votre stratégie.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPromptCard(Map<String, String> agent, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(agent['icon']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                agent['name']!,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prompt délégué :',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            agent['prompt']!,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPlanCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.2),
            colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'Plan Stratégique Final',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanItem('1. Phase d\'Attraction', 'Lancement des vidéos virales via Video Agent.'),
          _buildPlanItem('2. Phase d\'Engagement', 'Diffusion des slogans via Slogan Agent.'),
          _buildPlanItem('3. Phase de Conversion', 'Présentation des détails via Product Agent.'),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Stratégie prête à être déployée !',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
