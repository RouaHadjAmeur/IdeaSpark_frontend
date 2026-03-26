import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../models/google_calendar_tokens.dart';

class GoogleCalendarTokenScreen extends StatefulWidget {
  const GoogleCalendarTokenScreen({super.key});

  @override
  State<GoogleCalendarTokenScreen> createState() =>
      _GoogleCalendarTokenScreenState();
}

class _GoogleCalendarTokenScreenState
    extends State<GoogleCalendarTokenScreen> {
  final _accessCtrl = TextEditingController();
  final _refreshCtrl = TextEditingController();
  bool _isSaving = false;
  bool _accessVisible = false;
  bool _refreshVisible = false;

  @override
  void dispose() {
    _accessCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final access = _accessCtrl.text.trim();
    final refresh = _refreshCtrl.text.trim();

    if (access.isEmpty || refresh.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les deux champs'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tokens = GoogleCalendarTokens(
        accessToken: access,
        refreshToken: refresh,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final ok = await GoogleCalendarStorageService.saveTokens(tokens);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chevron_left_rounded,
                size: 22, color: cs.onSurface),
          ),
        ),
        title: Text(
          'Connecter Google Calendar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Comment obtenir vos tokens ?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _step('1', 'Cliquez "Connecter Google Calendar" dans le plan', cs),
                  _step('2', 'Cliquez "Ouvrir Google" et autorisez l\'accès', cs),
                  _step('3', 'Copiez l\'Access Token et le Refresh Token affichés', cs),
                  _step('4', 'Collez-les ci-dessous et sauvegardez', cs),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Access Token
            Text('Access Token',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            _tokenField(
              controller: _accessCtrl,
              hint: 'ya29.a0ATkoCc...',
              icon: Icons.key_rounded,
              visible: _accessVisible,
              onToggle: () => setState(() => _accessVisible = !_accessVisible),
              cs: cs,
            ),
            const SizedBox(height: 6),
            _pasteButton(_accessCtrl, cs),

            const SizedBox(height: 24),

            // Refresh Token
            Text('Refresh Token',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            _tokenField(
              controller: _refreshCtrl,
              hint: '1//03...',
              icon: Icons.refresh_rounded,
              visible: _refreshVisible,
              onToggle: () =>
                  setState(() => _refreshVisible = !_refreshVisible),
              cs: cs,
            ),
            const SizedBox(height: 6),
            _pasteButton(_refreshCtrl, cs),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSaving ? 'Sauvegarde...' : 'Connecter Google Calendar',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), shape: BoxShape.circle),
              child: Center(
                child: Text(num,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ),
          ],
        ),
      );

  Widget _tokenField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool visible,
    required VoidCallback onToggle,
    required ColorScheme cs,
  }) =>
      TextField(
        controller: controller,
        obscureText: !visible,
        maxLines: visible ? 3 : 1,
        style: TextStyle(fontSize: 12, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          prefixIcon: Icon(icon, size: 18, color: cs.primary),
          suffixIcon: IconButton(
            icon: Icon(
                visible ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: cs.onSurfaceVariant),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF4285F4), width: 1.5)),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      );

  Widget _pasteButton(TextEditingController ctrl, ColorScheme cs) =>
      GestureDetector(
        onTap: () async {
          final data = await Clipboard.getData('text/plain');
          if (data?.text != null) ctrl.text = data!.text!.trim();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_paste_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text('Coller depuis le presse-papiers',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
