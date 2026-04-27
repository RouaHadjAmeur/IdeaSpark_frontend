import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../core/utils/image_helper.dart';

class CollaboratorsModal extends StatefulWidget {
  final String planId;
  const CollaboratorsModal({super.key, required this.planId});

  @override
  State<CollaboratorsModal> createState() => _CollaboratorsModalState();
}

class _CollaboratorsModalState extends State<CollaboratorsModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaborationViewModel>().loadCollaborators(widget.planId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<CollaborationViewModel>();

    final isBrandOwner = context.watch<AuthViewModel>().isBrandOwner;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collaborateurs',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Invite section — Brand Owner only ──────────────────────────
          if (isBrandOwner) ...[
            TextField(
              controller: _searchController,
              onChanged: (val) => vm.searchUsers(val),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (vm.searchResults.isNotEmpty) ...[
              Text(
                'Résultats de recherche',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: vm.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = vm.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: ImageHelper.getImageProvider(user.profilePicture),
                        child: user.profilePicture == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.role.name ?? user.email ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          try {
                            await vm.inviteCollaborator(widget.planId, user.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invitation envoyée !')),
                            );
                            _searchController.clear();
                            vm.searchUsers('');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
          ] else ...[
            // Non-premium lock banner
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/subscription');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only Brand Owners can invite collaborators. Tap to upgrade.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Équipe actuelle',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: vm.isLoading && vm.collaborators.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: vm.collaborators.length,
                    itemBuilder: (context, index) {
                      final collab = vm.collaborators[index];
                      final user = collab['userId'];
                      final isOwner = collab['role'] == 'owner';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: ImageHelper.getImageProvider(user['profile_img']),
                          child: user['profile_img'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user['name'] ?? 'Utilisateur'),
                        subtitle: Text(collab['role'] ?? 'Collaborateur'),
                        trailing: !isOwner
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: isBrandOwner
                                    ? () => vm.removeCollaborator(widget.planId, user['_id'] ?? user['id'])
                                    : null,
                              )
                            : const Icon(Icons.verified, color: Colors.blue, size: 20),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
