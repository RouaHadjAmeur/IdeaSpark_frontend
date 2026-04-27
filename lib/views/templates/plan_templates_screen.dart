import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/plan.dart';

class PlanTemplate {
  final String id;
  final String name;
  final String description;
  final int durationWeeks;
  final int postingFrequency;
  final int totalPosts;
  final DateTime savedAt;

  PlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.postingFrequency,
    required this.totalPosts,
    required this.savedAt,
  });

  factory PlanTemplate.fromPlan(Plan plan) => PlanTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: plan.name,
        description: '${plan.objective.label} • ${plan.durationWeeks} semaines',
        durationWeeks: plan.durationWeeks,
        postingFrequency: plan.postingFrequency,
        totalPosts: plan.phases.fold(0, (s, p) => s + p.contentBlocks.length),
        savedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'durationWeeks': durationWeeks,
        'postingFrequency': postingFrequency,
        'totalPosts': totalPosts,
        'savedAt': savedAt.toIso8601String(),
      };

  factory PlanTemplate.fromJson(Map<String, dynamic> json) => PlanTemplate(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        durationWeeks: json['durationWeeks'],
        postingFrequency: json['postingFrequency'],
        totalPosts: json['totalPosts'],
        savedAt: DateTime.parse(json['savedAt']),
      );
}

class PlanTemplatesService {
  static const _key = 'plan_templates';

  static Future<List<PlanTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => PlanTemplate.fromJson(e)).toList();
  }

  static Future<void> save(PlanTemplate t) async {
    final list = await getAll();
    list.insert(0, t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((t) => t.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}

class PlanTemplatesScreen extends StatefulWidget {
  const PlanTemplatesScreen({super.key});

  @override
  State<PlanTemplatesScreen> createState() => _PlanTemplatesScreenState();
}

class _PlanTemplatesScreenState extends State<PlanTemplatesScreen> {
  List<PlanTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await PlanTemplatesService.getAll();
    if (mounted) setState(() { _templates = t; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
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
                  Text('Templates de Plans',
                      style: GoogleFonts.syne(
                          fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_templates.length}',
                        style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _templates.isEmpty
                      ? _buildEmpty(cs)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _templates.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(_templates[i], cs),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bookmark_border_rounded,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucun template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Sauvegardez un plan comme template\npour le réutiliser plus tard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ]),
      );

  Widget _buildCard(PlanTemplate t, ColorScheme cs) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_rounded, color: Color(0xFF9C27B0), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(t.description,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _chip('${t.durationWeeks}w', cs),
                _chip('${t.postingFrequency}/wk', cs),
                _chip('${t.totalPosts} posts', cs),
              ]),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
            onPressed: () async {
              await PlanTemplatesService.delete(t.id);
              await _load();
            },
          ),
        ]),
      );

  Widget _chip(String label, ColorScheme cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
      );
}
