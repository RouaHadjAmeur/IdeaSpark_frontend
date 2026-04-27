import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/google_calendar_service.dart';
import '../models/google_calendar_tokens.dart';

/// Button to connect Google Calendar account
/// 
/// This widget handles the OAuth flow for connecting a Google Calendar account.
/// It opens the authorization URL in the browser and handles the callback.
/// 
/// Example usage:
/// ```dart
/// GoogleCalendarConnectButton(
///   authToken: userToken,
///   onConnected: (tokens) {
///     // Save tokens and update UI
///     setState(() {
///       _googleTokens = tokens;
///     });
///   },
///   onError: (error) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(error)),
///     );
///   },
/// )
/// ```
class GoogleCalendarConnectButton extends StatefulWidget {
  /// JWT authentication token
  final String authToken;

  /// Callback when connection is successful
  final void Function(GoogleCalendarTokens tokens) onConnected;

  /// Callback when an error occurs
  final void Function(String error)? onError;

  /// Custom button text
  final String? buttonText;

  /// Button style
  final ButtonStyle? style;

  const GoogleCalendarConnectButton({
    super.key,
    required this.authToken,
    required this.onConnected,
    this.onError,
    this.buttonText,
    this.style,
  });

  @override
  State<GoogleCalendarConnectButton> createState() =>
      _GoogleCalendarConnectButtonState();
}

class _GoogleCalendarConnectButtonState
    extends State<GoogleCalendarConnectButton> {
  bool _isConnecting = false;
  final GoogleCalendarService _service = GoogleCalendarService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _connectGoogleCalendar() async {
    setState(() => _isConnecting = true);

    try {
      // 1. Get authorization URL
      final result = await _service.getAuthUrl(widget.authToken);

      if (!result.isSuccess) {
        _handleError(result.error ?? 'Erreur inconnue');
        return;
      }

      final authUrl = result.data!;

      // 2. Open in browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Show instructions to user
        if (mounted) {
          _showInstructions();
        }
      } else {
        _handleError('Impossible d\'ouvrir le navigateur');
      }
    } catch (e) {
      _handleError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Autorisation Google Calendar'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suivez ces étapes dans votre navigateur :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1. Connectez-vous à votre compte Google'),
            SizedBox(height: 8),
            Text('2. Autorisez l\'accès à votre calendrier'),
            SizedBox(height: 8),
            Text('3. Revenez à l\'application'),
            SizedBox(height: 16),
            Text(
              'Note: Vous devrez peut-être entrer manuellement le code d\'autorisation si la redirection automatique ne fonctionne pas.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isConnecting ? null : _connectGoogleCalendar,
      icon: _isConnecting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Image.asset(
              'assets/images/google_calendar_icon.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.calendar_today),
            ),
      label: Text(
        _isConnecting
            ? 'Connexion...'
            : widget.buttonText ?? 'Connecter Google Calendar',
      ),
      style: widget.style ??
          ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: const BorderSide(color: Colors.grey),
          ),
    );
  }
}
