import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/collection_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Shared bottom sheet to create a new collection. Pops with [CollectionModel] on success.
class CreateCollectionSheet extends StatefulWidget {
  const CreateCollectionSheet({super.key});

  @override
  State<CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<CreateCollectionSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isPrivate = true;
  int _selectedCoverIndex = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final supabase = SupabaseService();
      final created = await supabase.createCollection(name);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create collection. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isDark
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: mediaQuery.viewInsets.bottom + 20,
          ),
          color: bgColor,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'New Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Give your collection a name and choose who can see it.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _buildNameField(),
                const SizedBox(height: 18),
                _buildVisibilityToggle(),
                const SizedBox(height: 18),
                _buildCoverPicker(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _nameController.text.trim().isEmpty || _submitting
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.primaryAccent
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Create Journey'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Journey Name',
        labelStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        hintText: 'Summer in Italy',
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primaryAccent.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VisibilityOption(
                selected: _isPrivate,
                icon: Icons.lock,
                title: 'Private',
                subtitle: 'Only you can see this.',
                onTap: () {
                  setState(() => _isPrivate = true);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VisibilityOption(
                selected: !_isPrivate,
                icon: Icons.public,
                title: 'Public',
                subtitle: 'Friends and visitors can see this.',
                onTap: () {
                  setState(() => _isPrivate = false);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoverPicker() {
    final swatches = [
      [const Color(0xFF5E35B1), const Color(0xFF2196F3)],
      [const Color(0xFFFF8A65), const Color(0xFFFFD54F)],
      [const Color(0xFF26C6DA), const Color(0xFF00ACC1)],
      [const Color(0xFF66BB6A), const Color(0xFFAED581)],
      [const Color(0xFFEC407A), const Color(0xFFFFC1E3)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: swatches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colors = swatches[index];
              final selected = _selectedCoverIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCoverIndex = index);
                },
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.4),
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: selected ? 0.10 : 0.04),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
