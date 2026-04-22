import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';
import '../social/community_feed_screen.dart';
import 'brand_challenge_hub_screen.dart';
import 'challenges_screen.dart';

/// Routes to the right screen based on the user's role:
/// - Brand owner (premium) → BrandChallengeHubScreen
/// - Collaborator → ChallengesScreen
/// - Others → CommunityFeedScreen
class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isPremium) {
      return const BrandChallengeHubScreen();
    }

    if (!authVm.isBrandOwner) {
      return const ChallengesScreen();
    }

    return const CommunityFeedScreen();
  }
}
