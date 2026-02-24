import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Sub-page to edit Username, Bio, and Avatar. Glassmorphism style.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController(text: 'Traveler');
  final _bioController = TextEditingController(text: 'Pinning the world one photo at a time.');
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_markChanges);
    _bioController.addListener(_markChanges);
  }

  void _markChanges() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _AvatarPicker(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Avatar picker — coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              _GlassField(
                label: 'Username',
                controller: _usernameController,
                hint: 'Your display name',
                icon: LucideIcons.atSign,
              ),
              const SizedBox(height: 16),
              _GlassField(
                label: 'Bio',
                controller: _bioController,
                hint: 'Tell us a bit about yourself',
                icon: LucideIcons.penLine,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar circle with camera overlay. Placeholder until image_picker is wired.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(52),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.user,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-style text field with label.
class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppTheme.glassBlurSigma, sigmaY: AppTheme.glassBlurSigma),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    icon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
