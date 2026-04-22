import 'package:flutter/material.dart';

class InvitationDetailScreen extends StatelessWidget {
  final String invitationId;

  const InvitationDetailScreen({
    super.key,
    required this.invitationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'invitation')),
      body: const Center(child: Text('Invitation Detail Stub')),
    );
  }
}
