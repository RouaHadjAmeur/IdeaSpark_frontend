import 'package:flutter/material.dart';
import '../services/google_calendar_service.dart';
import '../models/google_calendar_tokens.dart';

/// Button to synchronize a plan with Google Calendar
/// 
/// This widget provides a button to sync all calendar entries from a plan
/// to the user's Google Calendar.
/// 
/// Example usage:
/// ```dart
/// GoogleCalendarSyncButton(
///   planId: plan.id!,
///   planName: plan.name,
///   authToken: userToken,
///   googleTokens: savedGoogleTokens,
///   onSyncComplete: (result) {
///     showDialog(
///       context: context,
///       builder: (context) => AlertDialog(
///         title: Text('Synchronisation terminée'),
///         content: Text('${result.synced}/${result.total} publications synchronisées'),
///       ),
///     );
///   },
/// )
/// ```
class GoogleCalendarSyncButton extends StatefulWidget {
  /// ID of the plan to synchronize
  final String planId;

  /// Name of the plan (for display)
  final String planName;

  /// JWT authentication token
  final String authToken;

  /// Google Calendar OAuth tokens
  final GoogleCalendarTokens googleTokens;

  /// Callback when sync completes successfully
  final void Function(SyncResult result)? onSyncComplete;

  /// Callback when an error occurs
  final void Function(String error)? onError;

  /// Custom button text
  final String? buttonText;

  /// Button style
  final ButtonStyle? style;

  /// Show icon
  final bool showIcon;

  const GoogleCalendarSyncButton({
    super.key,
    required this.planId,
    required this.planName,
    required this.authToken,
    required this.googleTokens,
    this.onSyncComplete,
    this.onError,
    this.buttonText,
    this.style,
    this.showIcon = true,
  });

  @override
  State<GoogleCalendarSyncButton> createState() =>
      _GoogleCalendarSyncButtonState();
}

class _GoogleCalendarSyncButtonState extends State<GoogleCalendarSyncButton> {
  bool _isSyncing = false;
  final GoogleCalendarService _service = GoogleCalendarService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _syncPlan() async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSyncing = true);

    try {
      final result = await _service.syncPlan(
        planId: widget.planId,
        tokens: widget.googleTokens,
        authToken: widget.authToken,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final syncResult = result.data!;
        
        // Show success message
        _showSuccessDialog(syncResult);

        // Call callback
        if (widget.onSyncComplete != null) {
          widget.onSyncComplete!(syncResult);
        }
      } else {
        _handleError(result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      _handleError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.sync, color: Colors.blue),
                SizedBox(width: 8),
                Text('Synchroniser avec Google Calendar'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous synchroniser toutes les publications du plan "${widget.planName}" avec votre Google Calendar ?',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les événements seront créés dans votre calendrier principal.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Synchroniser'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isFullSuccess ? Icons.check_circle : Icons.warning,
              color: result.isFullSuccess ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Synchronisation terminée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ ${result.synced}/${result.total} publications synchronisées',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (result.hasErrors) ...[
              const SizedBox(height: 12),
              Text(
                '❌ ${result.failed} échec(s)',
                style: const TextStyle(color: Colors.red),
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Erreurs:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                ...result.errors.take(3).map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '• $error',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
              ],
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vérifiez votre Google Calendar pour voir les événements.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleError(String error) {
    if (widget.onError != null) {
      widget.onError!(error);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _syncPlan,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSyncing ? null : _syncPlan,
      icon: _isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.showIcon
              ? const Icon(Icons.sync)
              : const SizedBox.shrink(),
      label: Text(
        _isSyncing
            ? 'Synchronisation...'
            : widget.buttonText ?? 'Synchroniser avec Google Calendar',
      ),
      style: widget.style ??
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
    );
  }
}
