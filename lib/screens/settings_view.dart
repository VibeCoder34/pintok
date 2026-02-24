import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';

/// Comprehensive Settings screen with glassmorphism, categorized sections,
/// and slide-in-from-right entrance animation.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Account'),
                  _GlassSection(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.userPen,
                        title: 'Edit Profile',
                        onTap: () => _openEditProfile(context),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.mail,
                        title: 'Email & Password',
                        onTap: () => _showComingSoon(context, 'Email & Password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Preferences'),
                  _GlassSection(
                    children: [
                      _ThemeModeTile(),
                      _DistanceUnitTile(),
                      _HapticFeedbackTile(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Privacy & Social'),
                  _GlassSection(
                    children: [
                      _PublicProfileTile(),
                      _MapVisibilityTile(),
                      _SettingsTile(
                        icon: LucideIcons.userX,
                        title: 'Blocked Users',
                        onTap: () => _showComingSoon(context, 'Blocked Users'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Notifications'),
                  _GlassSection(
                    children: [
                      _NotifTile(
                        title: 'New Pins from Friends',
                        valueKey: 'newPins',
                      ),
                      _NotifTile(
                        title: 'Someone Saved My Pin',
                        valueKey: 'savedMyPin',
                      ),
                      _NotifTile(
                        title: 'Trending Places Nearby',
                        valueKey: 'trending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Storage & AI'),
                  _GlassSection(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.imageOff,
                        title: 'Clear Image Cache',
                        subtitle: 'Free up phone space',
                        onTap: () => _clearImageCache(context),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.trash2,
                        title: 'AI History',
                        subtitle: 'Delete history of scanned photos',
                        onTap: () => _clearAIHistory(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Danger Zone', isDanger: true),
                  _GlassSection(
                    borderTint: AppColors.secondaryAccent.withValues(alpha: 0.35),
                    children: [
                      _DangerTile(
                        icon: LucideIcons.logOut,
                        title: 'Log Out',
                        onTap: () => _logOut(context),
                      ),
                      _DangerTile(
                        icon: LucideIcons.trash2,
                        title: 'Delete Account',
                        onTap: () => _deleteAccount(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 320.ms, curve: Curves.easeOut)
            .slideX(begin: 0.08, end: 0, duration: 380.ms, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  void _clearImageCache(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image cache cleared'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  void _clearAIHistory(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Clear AI History'),
        content: const Text(
          'This will permanently delete the history of your scanned photos. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI history cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _logOut(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Account'),
        content: const Text(
          'Permanently delete your account and all data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header: semi-transparent bold label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.isDanger = false});

  final String title;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDanger
              ? AppColors.secondaryAccent.withValues(alpha: 0.95)
              : AppColors.textSecondary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Glass panel wrapping a column of tiles.
class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.children,
    this.borderTint,
  });

  final List<Widget> children;
  final Color? borderTint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTheme.glassBlurSigma, sigmaY: AppTheme.glassBlurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: borderTint ?? Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Standard settings row: icon, title, optional subtitle, trailing chevron.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: AppColors.textSecondary),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Danger zone tile: red-tinted text and icon.
class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  static final Color _dangerColor = AppColors.secondaryAccent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: _dangerColor),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _dangerColor,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: _dangerColor.withValues(alpha: 0.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Theme mode selector (Dark / Light / System).
class _ThemeModeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListTile(
      leading: Icon(LucideIcons.palette, size: 22, color: AppColors.textSecondary),
      title: Text(
        'Theme Mode',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: SizedBox(
        width: 120,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppThemeMode>(
            value: settings.themeMode,
            isExpanded: true,
            dropdownColor: AppColors.surfaceDark,
            icon: Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
            items: AppThemeMode.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        settings.themeMode == m ? _label(m) : _label(m),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                HapticFeedback.selectionClick();
                settings.themeMode = v;
              }
            },
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  String _label(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

/// Distance unit: Kilometers / Miles.
class _DistanceUnitTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListTile(
      leading: Icon(LucideIcons.ruler, size: 22, color: AppColors.textSecondary),
      title: Text(
        'Distance Units',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: SizedBox(
        width: 130,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<DistanceUnit>(
            value: settings.distanceUnit,
            isExpanded: true,
            dropdownColor: AppColors.surfaceDark,
            icon: Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
            items: DistanceUnit.values
                .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(
                        u == DistanceUnit.kilometers ? 'Kilometers' : 'Miles',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                HapticFeedback.selectionClick();
                settings.distanceUnit = v;
              }
            },
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Haptic feedback toggle.
class _HapticFeedbackTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListTile(
      leading: Icon(LucideIcons.hand, size: 22, color: AppColors.textSecondary),
      title: Text(
        'Haptic Feedback',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Switch(
        value: settings.hapticFeedback,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          settings.hapticFeedback = v;
        },
        activeColor: AppColors.primaryAccent,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Public profile toggle (when off, only Friends see collections).
class _PublicProfileTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListTile(
      leading: Icon(LucideIcons.globe, size: 22, color: AppColors.textSecondary),
      title: Text(
        'Public Profile',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'When off, only friends can see your collections',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: settings.publicProfile,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          settings.publicProfile = v;
        },
        activeColor: AppColors.primaryAccent,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Map visibility: who can see live-pinned locations.
class _MapVisibilityTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListTile(
      onTap: () => _showMapVisibilityPicker(context, settings),
      leading: Icon(LucideIcons.mapPin, size: 22, color: AppColors.textSecondary),
      title: Text(
        'Map Visibility',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        settings.mapVisibilityLabel,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  void _showMapVisibilityPicker(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who can see your live-pinned locations?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...MapVisibility.values.map((v) {
                final label = v == MapVisibility.everyone
                    ? 'Everyone'
                    : v == MapVisibility.friends
                        ? 'Friends only'
                        : 'Nobody';
                return ListTile(
                  title: Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary)),
                  trailing: settings.mapVisibility == v
                      ? Icon(LucideIcons.check, color: AppColors.primaryAccent, size: 20)
                      : null,
                  onTap: () {
                    settings.mapVisibility = v;
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification toggle row.
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.title, required this.valueKey});

  final String title;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final value = valueKey == 'newPins'
        ? settings.notifNewPinsFromFriends
        : valueKey == 'savedMyPin'
            ? settings.notifSomeoneSavedMyPin
            : settings.notifTrendingNearby;

    void onChanged(bool v) {
      HapticFeedback.selectionClick();
      switch (valueKey) {
        case 'newPins':
          settings.notifNewPinsFromFriends = v;
          break;
        case 'savedMyPin':
          settings.notifSomeoneSavedMyPin = v;
          break;
        case 'trending':
          settings.notifTrendingNearby = v;
          break;
      }
    }

    return ListTile(
      leading: Icon(
        valueKey == 'newPins'
            ? LucideIcons.bell
            : valueKey == 'savedMyPin'
                ? LucideIcons.bookmark
                : LucideIcons.trendingUp,
        size: 22,
        color: AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryAccent,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
