import 'package:flutter/material.dart';
import '../models/google_calendar_tokens.dart';
import '../services/google_calendar_storage_service.dart';
import 'google_calendar_connect_button.dart';
import 'google_calendar_sync_button.dart';

/// Complete Google Calendar integration card
/// 
/// This widget shows the connection status and provides buttons
/// to connect or sync with Google Calendar.
/// 
/// Example usage:
/// ```dart
/// GoogleCalendarIntegrationCard(
///   planId: plan.id!,
///   planName: plan.name,
///   authToken: userToken,
/// )
/// ```
class GoogleCalendarIntegrationCard extends StatefulWidget {
  /// ID of the plan to synchronize (optional, if null shows general connection)
  final String? planId;

  /// Name of the plan (for display)
  final String? planName;

  /// JWT authentication token
  final String authToken;

  /// Callback when sync completes
  final VoidCallback? onSyncComplete;

  const GoogleCalendarIntegrationCard({
    super.key,
    this.planId,
    this.planName,
    required this.authToken,
    this.onSyncComplete,
  });

  @override
  State<GoogleCalendarIntegrationCard> createState() =>
      _GoogleCalendarIntegrationCardState();
}

class _GoogleCalendarIntegrationCardState
    extends State<GoogleCalendarIntegrationCard> {
  GoogleCalendarTokens? _tokens;
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    setState(() => _isLoading = true);

    final tokens = await GoogleCalendarStorageService.getTokens();
    final isConnected = await GoogleCalendarStorageService.isConnected();

    if (mounted) {
      setState(() {
        _tokens = tokens;
        _isConnected = isConnected;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConnect(GoogleCalendarTokens tokens) async {
    await GoogleCalendarStorageService.saveTokens(tokens);
    await _loadTokens();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Google Calendar connecté avec succès !'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnecter Google Calendar'),
        content: const Text(
          'Êtes-vous sûr de vouloir déconnecter votre compte Google Calendar ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GoogleCalendarStorageService.clearTokens();
      await _loadTokens();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar déconnecté'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Calendar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isConnected ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isConnected ? 'Connecté' : 'Non connecté',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isConnected ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isConnected)
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: _handleDisconnect,
                    tooltip: 'Déconnecter',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isConnected
                          ? 'Synchronisez automatiquement vos publications avec votre calendrier Google.'
                          : 'Connectez votre compte Google pour synchroniser vos publications.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            if (!_isConnected)
              SizedBox(
                width: double.infinity,
                child: GoogleCalendarConnectButton(
                  authToken: widget.authToken,
                  onConnected: _handleConnect,
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              )
            else if (widget.planId != null && widget.planName != null)
              SizedBox(
                width: double.infinity,
                child: GoogleCalendarSyncButton(
                  planId: widget.planId!,
                  planName: widget.planName!,
                  authToken: widget.authToken,
                  googleTokens: _tokens!,
                  onSyncComplete: (result) {
                    if (widget.onSyncComplete != null) {
                      widget.onSyncComplete!();
                    }
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Votre compte est connecté. Vous pouvez maintenant synchroniser vos plans.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
