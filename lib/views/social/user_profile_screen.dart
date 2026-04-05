import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../view_models/social_view_model.dart';
import '../../core/utils/image_helper.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  AppUser? _user;
  bool _isLoading = true;
  final SocialService _socialService = SocialService();
  late SocialViewModel _socialVm;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _socialVm = context.read<SocialViewModel>();
    _socialVm.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _socialVm.removeListener(_onViewModelChange);
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final vm = context.read<SocialViewModel>();
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => vm.clearError(),
          ),
        ),
      );
    }
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _socialService.getUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr('user_not_found'))),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final socialVm = context.watch<SocialViewModel>();
    final isFollowing = socialVm.isFollowing(widget.userId);
    final isRequested = socialVm.isRequested(widget.userId);
    final isFollower = socialVm.isFollower(widget.userId);

    String buttonText = 'Follow';
    if (isFollowing) {
      buttonText = 'Followed';
    } else if (isRequested) {
      buttonText = 'Sent';
    } else if (isFollower) {
      buttonText = 'Follow back';
    }

    Color bgColor = colorScheme.primary;
    Color fgColor = colorScheme.onPrimary;
    BorderSide? side;

    if (isFollowing) {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    } else if (isRequested) {
      bgColor = colorScheme.secondary.withValues(alpha: 0.2);
      fgColor = colorScheme.secondary;
      side = BorderSide(color: colorScheme.secondary);
    } else if (isFollower) {
      bgColor = colorScheme.tertiary;
      fgColor = colorScheme.onTertiary;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.username ?? _user!.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundImage: ImageHelper.getImageProvider(_user!.profilePicture),
              child: _user!.profilePicture == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_user!.role != null) ...[
              const SizedBox(height: 4),
              Text(
                _user!.role!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Follow Button
            SizedBox(
              width: 200,
              child: FilledButton(
                onPressed: () => socialVm.toggleFollow(widget.userId),
                style: FilledButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  side: side,
                ),
                child: Text(buttonText),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Skills', _user!.skills?.length ?? 0),
                _buildStat('Interests', _user!.interests?.length ?? 0),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Public Info
            _buildSection(context, 'About', Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.email_outlined, _user!.email),
                if (_user!.role != null) _buildInfoRow(Icons.work_outline, _user!.role!),
              ],
            )),
            
            const SizedBox(height: 24),
            
            if (_user!.skills != null && _user!.skills!.isNotEmpty)
              _buildSection(context, 'Skills', Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.skills!.map((s) => Chip(label: Text(s))).toList(),
              )),
              
            const SizedBox(height: 24),

            if (_user!.interests != null && _user!.interests!.isNotEmpty)
              _buildSection(context, 'Interests', Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.interests!.map((i) => Chip(
                  label: Text(i),
                  backgroundColor: colorScheme.secondaryContainer,
                )).toList(),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
