import '../services/auth_service.dart';

/// Centralised permission checks for brand owner vs collaborator.
///
/// Usage:
///   final perms = PermissionService(currentUser);
///   if (perms.canApprovePosts) { ... }
class PermissionService {
  final AppUser? user;

  const PermissionService(this.user);

  bool get isBrandOwner => user?.role == UserRole.brandOwner;
  bool get isCollaborator => user?.role == UserRole.collaborator;

  // ── Brand Owner exclusive ─────────────────────────────────────────────────

  /// Can create / edit / delete brands.
  bool get canManageBrands => isBrandOwner;

  /// Can create / edit / delete campaigns (plans).
  bool get canManageCampaigns => isBrandOwner;

  /// Can create / edit / delete phases inside a campaign.
  bool get canManagePhases => isBrandOwner;

  /// Can invite or remove collaborators.
  bool get canManageCollaborators => isBrandOwner;

  /// Can view the campaign budget and KPI targets.
  bool get canViewBudget => isBrandOwner;

  /// Can view the analytics dashboard.
  bool get canViewAnalytics => isBrandOwner;

  /// Can view the Brand DNA configuration screen.
  bool get canEditBrandDNA => isBrandOwner;

  /// Can approve or request revision on a submitted post.
  bool get canApprovePosts => isBrandOwner;

  /// Can see all collaborators' posts inside a campaign.
  bool get canViewAllCollaboratorPosts => isBrandOwner;

  /// Can see the Approbations queue tab.
  bool get canViewApprobationsTab => isBrandOwner;

  /// Can activate a draft plan.
  bool get canActivatePlan => isBrandOwner;

  /// Can delete a plan.
  bool get canDeletePlan => isBrandOwner;

  // ── Collaborator exclusive ────────────────────────────────────────────────

  /// Can submit a post for review.
  bool get canSubmitPost => isCollaborator;

  /// Can mark a post as published after approval.
  bool get canMarkPublished => isCollaborator;

  /// Can use AI generation tools on their own posts.
  bool get canUseAIGeneration => true; // both roles

  // ── Shared ────────────────────────────────────────────────────────────────

  /// Can view the campaign card (read-only overview).
  bool get canViewCampaign => true;

  /// Can view their own assigned posts.
  bool get canViewOwnPosts => true;
}
