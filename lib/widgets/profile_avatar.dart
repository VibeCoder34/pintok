import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Allowed Bitmoji keys for profile avatar. Asset path: assets/bitmojis/{key}.png
const List<String> kBitmojiAvatarKeys = [
  'gencerkek',
  'genckadin',
  'yaslierkek',
  'yaslikadin',
];

String bitmojiAssetPath(String key) => 'assets/bitmojis/$key.png';

/// Tappable profile avatar: shows Bitmoji (if [avatarKey] set), else [avatarUrl], else placeholder.
/// When [onAvatarChanged] is provided, tapping opens a sheet to pick a Bitmoji; selection is saved to DB and [onAvatarChanged] is called.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.avatarKey,
    this.radius = 40,
    this.onAvatarChanged,
  });

  final String? avatarUrl;
  final String? avatarKey;
  final double radius;
  final VoidCallback? onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final child = _GlowAvatar(
      avatarUrl: avatarUrl,
      avatarKey: avatarKey,
      radius: radius,
    );
    if (onAvatarChanged == null) return child;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBitmojiPicker(context);
      },
      child: child,
    );
  }

  void _showBitmojiPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _BitmojiPickerModal(
        currentKey: avatarKey,
        onSelect: (key) async {
          Navigator.of(ctx).pop();
          await SupabaseService().updateProfileAvatarKey(key);
          if (context.mounted) onAvatarChanged?.call();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

/// Circular avatar with glow: Bitmoji asset, or network image, or placeholder icon.
class _GlowAvatar extends StatelessWidget {
  const _GlowAvatar({
    this.avatarUrl,
    this.avatarKey,
    this.radius = 40,
  });

  final String? avatarUrl;
  final String? avatarKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool useBitmoji = avatarKey != null &&
        avatarKey!.isNotEmpty &&
        kBitmojiAvatarKeys.contains(avatarKey);
    final String? assetPath =
        useBitmoji ? bitmojiAssetPath(avatarKey!) : null;
    final bool hasNetworkImage =
        !useBitmoji && avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.surfaceDark,
            backgroundImage: hasNetworkImage ? NetworkImage(avatarUrl!) : null,
            child: assetPath != null
                ? ClipOval(
                    child: Image.asset(
                      assetPath,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                    ),
                  )
                : (hasNetworkImage
                    ? null
                    : Icon(
                        LucideIcons.user,
                        size: radius + 4,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      )),
          ),
        ),
      ),
    );
  }
}

/// Bitmoji seçim modalı: büyük avatar grid, başlık ve iptal.
class _BitmojiPickerModal extends StatelessWidget {
  const _BitmojiPickerModal({
    required this.currentKey,
    required this.onSelect,
    required this.onCancel,
  });

  final String? currentKey;
  final void Function(String key) onSelect;
  final VoidCallback onCancel;

  static const double _avatarSize = 130;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profil fotoğrafı seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
              children: kBitmojiAvatarKeys.map((key) {
                final isSelected = currentKey == key;
                return GestureDetector(
                  onTap: () => onSelect(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryAccent
                            : Colors.transparent,
                        width: 4,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryAccent
                                    .withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        bitmojiAssetPath(key),
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
