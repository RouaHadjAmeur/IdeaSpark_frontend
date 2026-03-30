import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/view_models/profile_view_model.dart';
import 'package:ideaspark/core/utils/image_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _roleController;
  late TextEditingController _skillsController;
  late TextEditingController _interestsController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    _nameController = TextEditingController(text: vm.displayName);
    _phoneController = TextEditingController(text: vm.phone);
    _usernameController = TextEditingController(text: vm.username ?? '');
    _roleController = TextEditingController(text: vm.role ?? '');
    _skillsController = TextEditingController(text: vm.skills.join(', '));
    _interestsController = TextEditingController(text: vm.interests.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        context.read<ProfileViewModel>().setSelectedImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sélection de l'image : $e")),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final vm = context.read<ProfileViewModel>();
    final success = await vm.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      role: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
      skills: _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      interests: _interestsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('profile_updated'))),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr('edit_profile'),
              style: GoogleFonts.syne(fontWeight: FontWeight.w700),
            ),
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (vm.profilePicture == null && vm.selectedImage == null)
                        ? LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: vm.selectedImage != null
                        ? DecorationImage(
                            image: FileImage(vm.selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : vm.profilePicture != null
                            ? DecorationImage(
                                image: ImageHelper.getImageProvider(vm.profilePicture),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                          child: (vm.profilePicture == null && vm.selectedImage == null)
                              ? const Center(
                                  child: Text('👤', style: TextStyle(fontSize: 40)),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (vm.updateProfileErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.errorColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      vm.updateProfileErrorMessage!,
                      style: TextStyle(color: context.errorColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                _buildTextField(
                  controller: TextEditingController(text: vm.email),
                  label: context.tr('email'),
                  hint: '',
                  icon: Icons.email_outlined,
                  colorScheme: colorScheme,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _nameController,
                  label: context.tr('full_name'),
                  hint: context.tr('full_name_hint'),
                  icon: Icons.person_outline_rounded,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _phoneController,
                  label: context.tr('phone'),
                  hint: context.tr('phone_hint'),
                  icon: Icons.phone_outlined,
                  colorScheme: colorScheme,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _usernameController,
                  label: 'Nom d\'utilisateur',
                  hint: 'Ex: @jean_doe',
                  icon: Icons.alternate_email_rounded,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _roleController,
                  label: 'Rôle professionnel',
                  hint: 'Ex: Créateur de contenu, Marketer',
                  icon: Icons.work_outline_rounded,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _skillsController,
                  label: 'Compétences (séparées par des virgules)',
                  hint: 'Ex: Vidéo, Design, Stratégie',
                  icon: Icons.star_outline_rounded,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _interestsController,
                  label: 'Intérêts (séparées par des virgules)',
                  hint: 'Ex: IA, Entrepreneuriat, Tech',
                  icon: Icons.interests_outlined,
                  colorScheme: colorScheme,
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: vm.isUpdateProfileLoading ? null : _saveChanges,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: vm.isUpdateProfileLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('save_changes'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: readOnly 
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3) 
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
