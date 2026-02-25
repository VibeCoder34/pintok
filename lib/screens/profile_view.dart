import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/collection_model.dart';
import '../models/library_models.dart';
import '../models/profile_data.dart';
import '../models/pin_model.dart';
import '../services/supabase_service.dart';
import 'collection_detail_view.dart';
import 'create_collection_sheet.dart';
import '../theme/app_theme.dart';

/// My Journey: profile header + tabbed My Pins (owned) / Saved (bookmarked from feed).
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabase = SupabaseService();
  UserProfile? _profile;
  List<PinModel> _myPins = [];
  List<Collection> _profileCollections = [];
  int _selectedTabIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final i = _tabController.index;
      if (i != _selectedTabIndex && mounted) setState(() => _selectedTabIndex = i);
    });
    _loadProfileAndPins();
  }

  Future<void> _loadProfileAndPins() async {
    setState(() => _loading = true);
    final profileRow = await _supabase.getCurrentUserProfile();
    final pins = await _supabase.getPins(null);
    final collections = await _supabase.getCollections();
    final pinsCount = await _supabase.getMyPinsCount();
    final collectionsCount = await _supabase.getMyCollectionsCount();
    final countByCollection = <String, int>{};
    for (final p in pins) {
      countByCollection[p.collectionId] = (countByCollection[p.collectionId] ?? 0) + 1;
    }
    final mapped = collections
        .map(
          (c) => Collection(
            id: c.id,
            name: c.name,
            pinCount: countByCollection[c.id] ?? 0,
            coverImageUrl: '',
            isPrivate: false,
          ),
        )
        .toList();
    if (mounted) {
      setState(() {
        _profile = UserProfile(
          username: (profileRow?['username'] as String?) ?? 'traveler',
          bio: (profileRow?['bio'] as String?) ??
              'No adventures written yet.',
          avatarUrl: profileRow?['avatar_url'] as String?,
          pinsCount: pinsCount,
          collectionsCount: collectionsCount,
          impactCount: 0,
        );
        _myPins = pins;
        _profileCollections = mapped;
        _loading = false;
      });
    }
  }

  Future<void> _onCreateCollectionTapped() async {
    final created = await showModalBottomSheet<CollectionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateCollectionSheet(),
    );
    if (!mounted || created == null) return;
    setState(() {
      _profileCollections.insert(
        0,
        Collection(
          id: created.id,
          name: created.name,
          pinCount: 0,
          coverImageUrl: '',
          isPrivate: false,
        ),
      );
    });
    await _loadProfileAndPins();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey created!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _profile == null
                  ? const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    )
                  : _ProfileHeader(profile: _profile!),
            ),
            SliverToBoxAdapter(
              child: _ShareProfileButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile link copied!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _ProfileTabBar(
                selectedIndex: _selectedTabIndex,
                onTabTap: _onTabTap,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                  : _MyPinsTab(pins: _myPins, onRefresh: _loadProfileAndPins),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                  : const _SavedTabEmpty(),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                  : _ProfileCollectionsTab(
                      collections: _profileCollections,
                      onCreateTap: _onCreateCollectionTapped,
                      onRefresh: _loadProfileAndPins,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab bar: My Pins | Saved | Collections.
class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.selectedIndex,
    required this.onTabTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              icon: LucideIcons.mapPin,
              label: 'My Pins',
              isSelected: selectedIndex == 0,
              onTap: () => onTabTap(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabChip(
              icon: LucideIcons.bookmark,
              label: 'Saved',
              isSelected: selectedIndex == 1,
              onTap: () => onTabTap(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabChip(
              icon: LucideIcons.folderOpen,
              label: 'Collections',
              isSelected: selectedIndex == 2,
              onTap: () => onTabTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// My Pins tab: Pinterest-style grid of user's own pins. Empty state: Tap + to start.
class _MyPinsTab extends StatelessWidget {
  const _MyPinsTab({required this.pins, required this.onRefresh});

  final List<PinModel> pins;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.mapPin,
        title: 'No adventures yet.',
        subtitle: 'Start pinning to see your journey here.',
      );
    }
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        final height = 180.0 + (index % 3) * 28.0;
        return SizedBox(
          height: height,
          child: _PinCard(
            pin: pin,
            showCreator: false,
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: (50 * index).ms)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 320.ms,
              delay: (50 * index).ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

/// Placeholder for Saved tab until real "saved pins" wiring is implemented.
class _SavedTabEmpty extends StatelessWidget {
  const _SavedTabEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: LucideIcons.bookmark,
      title: 'No saved inspirations yet.',
      subtitle: 'Explore the feed to find your next journey!',
    );
  }
}

/// Collections tab: create card + grid of collections (open to detail, where pins can be saved).
class _ProfileCollectionsTab extends StatelessWidget {
  const _ProfileCollectionsTab({
    required this.collections,
    required this.onCreateTap,
    required this.onRefresh,
  });

  final List<Collection> collections;
  final VoidCallback onCreateTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 3 / 4,
      ),
      itemCount: collections.isEmpty ? 1 : collections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ProfileCreateCollectionCard(onTap: onCreateTap);
        }
        final collection = collections[index - 1];
        return _ProfileCollectionCard(
          collection: collection,
          onTap: () {
            Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(
                builder: (_) => CollectionDetailView(collection: collection),
              ),
            ).then((result) {
              if (result != null && (result['deleted'] == true || result['updated'] != null)) {
                onRefresh();
              }
            });
          },
        );
      },
    );
  }
}

class _ProfileCreateCollectionCard extends StatelessWidget {
  const _ProfileCreateCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plus,
                  size: 32,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  'New Journey',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _ProfileCollectionCard extends StatelessWidget {
  const _ProfileCollectionCard({
    required this.collection,
    required this.onTap,
  });

  final Collection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                  child: collection.coverImageUrl.isNotEmpty
                      ? Image.network(
                          collection.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderCover(),
                        )
                      : _placeholderCover(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.pinCount} Pins',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: AppColors.primaryAccent.withValues(alpha: 0.2),
      child: Icon(
        LucideIcons.mapPin,
        size: 40,
        color: AppColors.primaryAccent.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Single pin card: image, name, location. If [showCreator], show "Saved from @x".
class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.pin,
    required this.showCreator,
  });

  final PinModel pin;
  final bool showCreator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              pin.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceDark,
                child: Icon(LucideIcons.imageOff, size: 40, color: AppColors.textSecondary),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pin.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (pin.metadata?['city'] as String?) ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for My Pins or Saved tab.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile header: avatar with glow, username, bio, Pins / Collections / Impact.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          _GlowAvatar(avatarUrl: profile.avatarUrl),
          const SizedBox(height: 16),
          Text(
            '@${profile.username}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: '${profile.pinsCount}', label: 'Pins'),
              _StatItem(value: '${profile.collectionsCount}', label: 'Collections'),
              _StatItem(value: '${profile.impactCount}', label: 'Impact'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular avatar with subtle glowing border.
class _GlowAvatar extends StatelessWidget {
  const _GlowAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
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
            radius: 40,
            backgroundColor: AppColors.surfaceDark,
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? Icon(LucideIcons.user, size: 44, color: AppColors.textSecondary.withValues(alpha: 0.8))
                : null,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Glassmorphism "Share Profile" button.
class _ShareProfileButton extends StatelessWidget {
  const _ShareProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.share2, size: 20, color: AppColors.primaryAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Share Profile',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
