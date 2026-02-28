import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fuel_gauge.dart';
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
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: true,
              title: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: false,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Subscription & Fuel'),
                  const _FuelStatusCard(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Account'),
                  _GlassSection(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.userPen,
                        title: 'Personal Information',
                        onTap: () => _openEditProfile(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Preferences (Travel Focus)'),
                  _GlassSection(
                    children: [
                      _ThemeModeTile(),
                      _DistanceUnitTile(),
                      _SettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () => _showComingSoon(context, 'Language'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Notifications'),
                  _GlassSection(
                    children: [
                      _NotifTile(
                        title: 'Push Notifications',
                        valueKey: 'newPins',
                      ),
                      _NotifTile(
                        title: 'Alerts for Nearby Gems',
                        valueKey: 'trending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Support & Legal'),
                  _GlassSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => _launchLegalUrl(
                          context,
                          'https://www.keremugurlu.com/pintok/terms/',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _launchLegalUrl(
                          context,
                          'https://www.keremugurlu.com/pintok/privacy/',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Account & Security (Supabase Sync)',
                    isDanger: true,
                  ),
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
                        title: 'Delete My Data & Account',
                        onTap: () => _deleteAccount(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'App Version: 1.0.0 (MVP)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
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

  Future<void> _launchLegalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.secondaryAccent,
                fontWeight: FontWeight.w600,
              ),
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
          'This will permanently delete all your pins, collections, and profile data. You will be signed out. This cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await SupabaseService().deleteUserData();
                await AuthService.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Account data deleted. You have been signed out.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}

/// Section header: semi-transparent bold label.
class _FuelStatusCard extends StatelessWidget {
  const _FuelStatusCard();

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.flame,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fuel Status',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your AI scan fuel for this month',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        FutureBuilder<Map<String, int?>>(
          future: SupabaseService().getAiScanQuota(),
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data;
            final used = data?['ai_scans_count'] ?? 0;
            final limit = data?['ai_scans_limit'];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FuelGauge(
                    scansUsed: used,
                    scansLimit: limit,
                    loading: loading,
                    compact: false,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Explorer upgrade coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Upgrade to Explorer',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ],
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
        'Map Theme',
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
            items: const [AppThemeMode.dark, AppThemeMode.light]
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      _labelStatic(m),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
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

  static String _labelStatic(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.dark:
        return 'Default Dark';
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
