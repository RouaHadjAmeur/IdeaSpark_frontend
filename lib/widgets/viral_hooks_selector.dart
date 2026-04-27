import 'package:flutter/material.dart';
import '../services/creative_ai_service.dart';

class ViralHooksSelector extends StatefulWidget {
  final Function(String) onHookSelected;
  final String? initialTopic;
  final String platform;

  const ViralHooksSelector({
    super.key,
    required this.onHookSelected,
    this.initialTopic,
    this.platform = 'instagram',
  });

  @override
  State<ViralHooksSelector> createState() => _ViralHooksSelectorState();
}

class _ViralHooksSelectorState extends State<ViralHooksSelector> {
  List<String> hooks = [];
  String? selectedHook;
  bool isLoading = false;
  String selectedTone = 'fun';
  final topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null) {
      topicController.text = widget.initialTopic!;
    }
  }

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }

  Future<void> _generateHooks() async {
    if (topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un sujet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final newHooks = await CreativeAIService.generateViralHooks(
        topic: topicController.text.trim(),
        platform: widget.platform,
        tone: selectedTone,
        count: 5,
      );

      if (mounted) {
        setState(() {
          hooks = newHooks;
          isLoading = false;
          selectedHook = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${newHooks.length} hooks générés !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                Text(
                  '🎣 Hooks Viraux',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Champ sujet
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Sujet du post',
                hintText: 'Ex: café, fitness, voyage...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.topic),
              ),
            ),
            const SizedBox(height: 12),

            // Sélecteur de ton
            Text(
              'Ton',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['fun', 'professional', 'inspirational', 'casual'].map((tone) {
                final isSelected = selectedTone == tone;
                return ChoiceChip(
                  label: Text(
                    tone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : cs.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => selectedTone = tone);
                  },
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bouton générer
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _generateHooks,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 20),
                label: Text(isLoading ? 'Génération...' : 'Générer des hooks'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Liste des hooks
            if (hooks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un hook',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hooks.length,
                itemBuilder: (context, index) {
                  final hook = hooks[index];
                  final isSelected = hook == selectedHook;

                  return InkWell(
                    onTap: () {
                      setState(() => selectedHook = hook);
                      widget.onHookSelected(hook);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected ? cs.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hook,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
