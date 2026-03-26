import 'package:flutter/material.dart';
import '../../models/google_calendar_tokens.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../widgets/google_calendar_integration_card.dart';

/// Screen for managing Google Calendar integration settings
/// 
/// This screen allows users to:
/// - Connect/disconnect their Google Calendar account
/// - View connection status
/// - Access sync options
class GoogleCalendarSettingsScreen extends StatefulWidget {
  final String authToken;

  const GoogleCalendarSettingsScreen({
    super.key,
    required this.authToken,
  });

  @override
  State<GoogleCalendarSettingsScreen> createState() =>
      _GoogleCalendarSettingsScreenState();
}

class _GoogleCalendarSettingsScreenState
    extends State<GoogleCalendarSettingsScreen> {
  GoogleCalendarTokens? _tokens;
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Integration card
                  GoogleCalendarIntegrationCard(
                    authToken: widget.authToken,
                    onSyncComplete: _loadStatus,
                  ),
                  const SizedBox(height: 24),

                  // Features section
                  const Text(
                    'Fonctionnalités',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    icon: Icons.sync,
                    title: 'Synchronisation automatique',
                    description:
                        'Synchronisez vos plans de publication avec Google Calendar en un clic.',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Rappels intelligents',
                    description:
                        'Recevez des notifications avant chaque publication programmée.',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.calendar_view_month,
                    title: 'Vue calendrier unifiée',
                    description:
                        'Visualisez toutes vos publications dans votre calendrier Google.',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),

                  // How it works section
                  const Text(
                    'Comment ça marche ?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildStepCard(
                    step: 1,
                    title: 'Connectez votre compte',
                    description:
                        'Autorisez IdeaSpark à accéder à votre Google Calendar.',
                  ),
                  const SizedBox(height: 12),

                  _buildStepCard(
                    step: 2,
                    title: 'Créez un plan de publication',
                    description:
                        'Utilisez le Strategic Content Manager pour créer votre plan.',
                  ),
                  const SizedBox(height: 12),

                  _buildStepCard(
                    step: 3,
                    title: 'Synchronisez',
                    description:
                        'Cliquez sur "Synchroniser" pour ajouter toutes les publications à votre calendrier.',
                  ),
                  const SizedBox(height: 24),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidentialité et sécurité',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vos données Google Calendar sont sécurisées. IdeaSpark n\'accède qu\'aux événements créés par l\'application et ne partage jamais vos informations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
