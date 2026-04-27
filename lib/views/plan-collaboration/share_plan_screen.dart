import 'package:flutter/material.dart';

class SharePlanScreen extends StatelessWidget {
  final String planId;
  final String planName;

  const SharePlanScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Partager $planName')),
      body: const Center(child: Text('Share Screen Stub')),
    );
  }
}
