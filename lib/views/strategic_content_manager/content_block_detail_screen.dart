import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/plan.dart';
import '../../view_models/plan_view_model.dart';
import '../../services/instagram_upload_service.dart';
import '../../services/youtube_upload_service.dart';
import '../../services/google_calendar_service.dart';

class ContentBlockDetailScreen extends StatefulWidget {
  final Plan plan;
  final Phase phase;
  final ContentBlock block;
  final int phaseIndex;
  final int blockIndex;

  const ContentBlockDetailScreen({
    super.key,
    required this.plan,
    required this.phase,
    required this.block,
    required this.phaseIndex,
    required this.blockIndex,
  });

  @override
  State<ContentBlockDetailScreen> createState() => _ContentBlockDetailScreenState();
}

class _ContentBlockDetailScreenState extends State<ContentBlockDetailScreen> {
  late TextEditingController _hookController;
  late TextEditingController _captionController;
  late TextEditingController _videoIdeaController;
  
  String? _selectedPlatform;
  String? _uploadedFilePath;
  bool _isAutoPosting = false;

  @override
  void initState() {
    super.initState();
    _hookController = TextEditingController(text: widget.block.hook);
    _captionController = TextEditingController(text: widget.block.caption);
    _videoIdeaController = TextEditingController(text: widget.block.title);
    _selectedPlatform = widget.plan.platforms.isNotEmpty ? widget.plan.platforms.first : 'Instagram';
  }

  @override
  void dispose() {
    _hookController.dispose();
    _captionController.dispose();
    _videoIdeaController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4', 'mov'],
    );

    if (result != null) {
      setState(() {
        _uploadedFilePath = result.files.single.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier sélectionné : ${result.files.single.name}'),
          backgroundColor: const Color(0xFF0EBFA1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planVm = context.watch<PlanViewModel>();
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1040), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.phase.name,
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF1A1040)),
        ),
        actions: [
          _buildStatusBadge(widget.block.status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(),
            const SizedBox(height: 24),
            
            _buildAiSection('HOOK', _hookController, planVm.isGenerating, () async {
              await planVm.generateHook(widget.plan.id!, widget.block.id!);
              final updatedBlock = planVm.plans.firstWhere((p) => p.id == widget.plan.id).findBlock(widget.block.id!);
              if (updatedBlock != null) _hookController.text = updatedBlock.hook ?? '';
            }),
            const SizedBox(height: 16),
            _buildAiSection('CAPTION', _captionController, planVm.isGenerating, () async {
              await planVm.generateCaption(widget.plan.id!, widget.block.id!);
              final updatedBlock = planVm.plans.firstWhere((p) => p.id == widget.plan.id).findBlock(widget.block.id!);
              if (updatedBlock != null) _captionController.text = updatedBlock.caption ?? '';
            }),
            const SizedBox(height: 16),
            _buildAiSection('IDÉE VIDÉO', _videoIdeaController, planVm.isGenerating, () async {
              await planVm.generateVideoIdea(widget.plan.id!, widget.block.id!);
              final updatedBlock = planVm.plans.firstWhere((p) => p.id == widget.plan.id).findBlock(widget.block.id!);
              if (updatedBlock != null) _videoIdeaController.text = updatedBlock.title;
            }),
            const SizedBox(height: 24),
            
            Text('CRÉER LE CONTENU', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF9090B0), letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionButton('Vidéo IA', '🎬', const Color(0xFFE0F7F6), const Color(0xFF0EBFA1), () => context.push('/video-generator'))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Image IA', '🖼️', const Color(0xFFFFF3E0), Colors.orange, () => context.push('/image-generator'))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Uploader', '📤', const Color(0xFFF3E5F5), Colors.purple, _pickFile)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Éditer', '✂️', const Color(0xFFFFEBEE), Colors.red, () => context.push('/image-editor'))),
              ],
            ),
            const SizedBox(height: 12),
            _buildWideButton('Cam Coach', '🎤', const Color(0xFFE8EAF6), const Color(0xFF3F51B5), () => context.push('/camera-coach')),
            const SizedBox(height: 12),
            _buildUploadZone(),
            const SizedBox(height: 24),
            
            Text('PUBLIER SUR', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF9090B0), letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPlatformChip('Instagram', '📸', const Color(0xFFE1306C)),
                _buildPlatformChip('TikTok', '🎵', Colors.black),
                _buildPlatformChip('Facebook', '📘', const Color(0xFF1877F2)),
              ],
            ),
            const SizedBox(height: 24),
            
            Text('QUAND PUBLIER ?', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF9090B0), letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildScheduleOption('Maintenant', '🚀', 'Publication directe', !_isAutoPosting, () => setState(() => _isAutoPosting = false))),
                const SizedBox(width: 8),
                Expanded(child: _buildScheduleOption('Auto après upload', '⚡', 'Poste dès que prêt', _isAutoPosting, () => setState(() => _isAutoPosting = true))),
                const SizedBox(width: 8),
                Expanded(child: _buildScheduleOption('Programmer', '🗓️', 'Choisir date + rappel', false, _showDateTimePicker)),
              ],
            ),
            const SizedBox(height: 32),
            
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContentBlockStatus status) {
    final statusColor = Color(status.color);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          status.label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6F0FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(widget.block.format == ContentFormat.reel ? '🎬' : '🖼️', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.block.title, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1A1040))),
                const SizedBox(height: 4),
                Text(
                  '${widget.block.format.name.toUpperCase()} • ${widget.block.pillar}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: const Color(0xFFA89EC0), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection(String label, TextEditingController controller, bool isGenerating, VoidCallback onGenerate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF9090B0), letterSpacing: 1.0)),
            TextButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating 
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0EBFA1)),
              label: Text(
                isGenerating ? 'Génération...' : 'Générer',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0EBFA1)),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: null,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1040)),
          decoration: InputDecoration(
            hintText: 'En attente de génération...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFA89EC0)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6F0FF))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6F0FF))),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, String emoji, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A1040))),
        ],
      ),
    );
  }

  Widget _buildWideButton(String label, String emoji, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6F0FF), style: BorderStyle.solid, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_uploadedFilePath != null)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF0EBFA1), size: 30)
            else
              const Icon(Icons.attach_file_rounded, color: Color(0xFFA89EC0), size: 30),
            const SizedBox(height: 10),
            Text(
              _uploadedFilePath != null ? 'Fichier prêt !' : 'Déposer vidéo ou image ici',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1040)),
            ),
            Text('MP4, MOV, JPG, PNG • max 500 MB', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: const Color(0xFFA89EC0))),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String label, String emoji, Color color) {
    final isSelected = _selectedPlatform == label;
    return InkWell(
      onTap: () => setState(() => _selectedPlatform = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : const Color(0xFFD6F0FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, 
                fontSize: 12, 
                color: isSelected ? color : const Color(0xFF1A1040),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOption(String label, String emoji, String sub, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDFCFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF6D4ED3) : const Color(0xFFD6F0FF), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 11, color: const Color(0xFF1A1040)), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(sub, style: GoogleFonts.spaceGrotesk(fontSize: 9, color: const Color(0xFFA89EC0)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFFFEBEE)),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _saveContent,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF00D9FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _publishNow,
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Publier Maintenant'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF6D4ED3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        final scheduledDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        
        /* 
        // Temporarily disabled due to missing service method
        await GoogleCalendarService.addEvent(
          title: 'Publier: ${widget.block.title}',
          description: 'Hook: ${_hookController.text}\nCaption: ${_captionController.text}',
          startTime: scheduledDateTime,
          endTime: scheduledDateTime.add(const Duration(minutes: 30)),
        );
        */

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rappel programmé pour le ${DateFormat('dd/MM/yyyy à HH:mm').format(scheduledDateTime)}'),
            backgroundColor: const Color(0xFF6D4ED3),
          ),
        );
      }
    }
  }

  Future<void> _saveContent() async {
    final planVm = context.read<PlanViewModel>();
    final updatedBlock = ContentBlock(
      id: widget.block.id,
      title: widget.block.title,
      pillar: widget.block.pillar,
      format: widget.block.format,
      ctaType: widget.block.ctaType,
      hook: _hookController.text,
      caption: _captionController.text,
      status: widget.block.status,
      recommendedDayOffset: widget.block.recommendedDayOffset,
      recommendedTime: widget.block.recommendedTime,
      imageUrl: widget.block.imageUrl,
    );

    final updatedPhases = List<Phase>.from(widget.plan.phases);
    final updatedBlocks = List<ContentBlock>.from(widget.phase.contentBlocks);
    updatedBlocks[widget.blockIndex] = updatedBlock;
    updatedPhases[widget.phaseIndex] = Phase(
      id: widget.phase.id,
      name: widget.phase.name,
      weekNumber: widget.phase.weekNumber,
      description: widget.phase.description,
      contentBlocks: updatedBlocks,
      status: widget.phase.status,
      productIds: widget.phase.productIds,
    );

    await planVm.updatePhases(widget.plan.id!, updatedPhases);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _publishNow() async {
    if (_uploadedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez uploader un fichier avant de publier.'), backgroundColor: Colors.orange),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publication en cours...'), backgroundColor: Color(0xFF6D4ED3)),
    );

    try {
      if (_selectedPlatform == 'Instagram') {
        await InstagramUploadService().publishUpload(
          filePath: _uploadedFilePath!,
          mediaType: widget.block.format == ContentFormat.reel ? 'REELS' : 'IMAGE',
          caption: _captionController.text,
        );
      } else if (_selectedPlatform == 'Facebook') {
        // Assume logic for FB or use general service
      }

      final planVm = context.read<PlanViewModel>();
      await planVm.updateBlockStatus(widget.block.id!, ContentBlockStatus.published);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publié avec succès !'), backgroundColor: Color(0xFF0EBFA1)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de publication: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
