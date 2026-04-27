import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SocialService _socialService = SocialService();
  
  List<AppUser> _searchResults = [];
  List<AppUser> _friends = [];
  List<dynamic> _pendingInvitations = [];
  bool _isLoading = false;
  bool _isLoadingFriends = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingFriends = true);
    try {
      final friends = await _socialService.getFriends();
      final invitations = await _socialService.getPendingInvitations();
      setState(() {
        _friends = friends.take(10).toList();
        _pendingInvitations = invitations;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() => _isLoadingFriends = false);
      _showError('Échec du chargement : $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _socialService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur recherche : $e');
    }
  }

  Future<void> _sendInvite(String userId) async {
    try {
      await _socialService.sendInvitation(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée !')),
        );
      }
    } catch (e) {
      _showError('Échec envoi : $e');
    }
  }

  Future<void> _handleInvite(String inviteId, bool accept) async {
    try {
      if (accept) {
        await _socialService.acceptInvitation(inviteId);
      } else {
        await _socialService.rejectInvitation(inviteId);
      }
      _loadInitialData(); // Rafraîchir
    } catch (e) {
      _showError('Erreur : $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: Column(
          children: [
            // BARRE DE RECHERCHE
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  // RÉSULTATS DE RECHERCHE
                  if (_searchController.text.isNotEmpty) ...[
                    _buildSectionHeader('Résultats de recherche'),
                    if (_searchResults.isEmpty && !_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Aucun utilisateur trouvé.')),
                      ),
                    ..._searchResults.map((user) => ListTile(
                      leading: _buildAvatar(user),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
                        onPressed: () => _sendInvite(user.id),
                      ),
                    )),
                    const Divider(),
                  ],

                  // INVITATIONS EN ATTENTE
                  if (_pendingInvitations.isNotEmpty) ...[
                    _buildSectionHeader('Invitations reçues'),
                    ..._pendingInvitations.map((invite) {
                      final sender = AppUser.fromJson(invite['sender']);
                      return ListTile(
                        leading: _buildAvatar(sender),
                        title: Text(sender.displayName),
                        subtitle: const Text('Souhaite devenir votre ami'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _handleInvite(invite['_id'], true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _handleInvite(invite['_id'], false),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                  ],

                  // LISTE D'AMIS
                  _buildSectionHeader('Mes Amis (10 derniers)'),
                  if (_isLoadingFriends)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Vous n\'avez pas encore d\'amis.')),
                    )
                  else
                    ..._friends.map((friend) => ListTile(
                      leading: _buildAvatar(friend),
                      title: Text(friend.displayName),
                      subtitle: Text(friend.email),
                      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                      onTap: () {
                        context.push('/chat/${friend.id}', extra: friend.displayName);
                      },
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    return CircleAvatar(
      backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
      child: user.profilePicture == null ? Text(user.displayName[0].toUpperCase()) : null,
    );
  }
}
