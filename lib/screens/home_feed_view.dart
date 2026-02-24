import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/home_feed_item.dart';
import '../repositories/home_feed_repository.dart';
import '../theme/app_theme.dart';

const double _kFollowingCardImageRadius = 16;
const double _kFollowingCardGap = 12;

/// Discovery heart of PinTok: Following (Instagram), Explore (Pinterest), Local (grid).
class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabControllerChanged);
  }

  void _onTabControllerChanged() {
    final index = _tabController.index.round();
    if (index != _selectedTabIndex && mounted) {
      setState(() => _selectedTabIndex = index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    _tabController.animateTo(index);
  }

  void _openPeek({
    required String heroTag,
    required String imageUrl,
    required String title,
    required String description,
    double? lat,
    double? lng,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PeekView(
        heroTag: heroTag,
        imageUrl: imageUrl,
        title: title,
        description: description,
        lat: lat,
        lng: lng,
      ),
    );
  }

  void _showAddToMapSuccess(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _AddToMapSuccessOverlay(),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Home',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CustomTabBar(
                selectedIndex: _selectedTabIndex,
                tabs: const ['Following', 'Explore', 'Local'],
                onTabTap: _onTabTap,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _FollowingTab(
                onPeek: _openPeek,
                onAddToMap: _showAddToMapSuccess,
              ),
              _ExploreTab(
                onPeek: _openPeek,
                onAddToMap: _showAddToMapSuccess,
              ),
              _LocalTab(
                onPeek: _openPeek,
                onAddToMap: _showAddToMapSuccess,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom tab bar: chip-style active, glowing underline.
class _CustomTabBar extends StatelessWidget {
  const _CustomTabBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabTap,
  });

  final int selectedIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primaryAccent.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[i],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppColors.primaryAccent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tab 1: Following — vertically scrollable social feed with lazy loading.
class _FollowingTab extends StatelessWidget {
  const _FollowingTab({
    required this.onPeek,
    required this.onAddToMap,
  });

  final void Function({
    required String heroTag,
    required String imageUrl,
    required String title,
    required String description,
    double? lat,
    double? lng,
  }) onPeek;
  final void Function(BuildContext) onAddToMap;

  @override
  Widget build(BuildContext context) {
    final posts = HomeFeedRepository.getFollowing();
    return ListView.builder(
      key: const PageStorageKey<String>('following_feed'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          key: ValueKey(post.id),
          children: [
            if (index > 0) const SizedBox(height: _kFollowingCardGap),
            FollowingPostCard(
              post: post,
              onTap: () => onPeek(
                heroTag: 'following_${post.id}',
                imageUrl: post.imageUrl,
                title: post.locationTag,
                description: post.caption,
                lat: post.lat,
                lng: post.lng,
              ),
              onAddToMap: () => onAddToMap(context),
            )
                .animate()
                .fadeIn(duration: 320.ms, delay: (40 * index).ms)
                .slideY(begin: 0.02, end: 0, duration: 360.ms, delay: (40 * index).ms, curve: Curves.easeOutCubic),
          ],
        );
      },
    );
  }
}

/// Single post card: header, yana kaydırılabilir fotoğraflar (Instagram gibi), konum metni, Add to My Map.
class FollowingPostCard extends StatefulWidget {
  const FollowingPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAddToMap,
  });

  final FollowingPost post;
  final VoidCallback onTap;
  final VoidCallback onAddToMap;

  @override
  State<FollowingPostCard> createState() => _FollowingPostCardState();
}

class _FollowingPostCardState extends State<FollowingPostCard> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    // Mock: aynı fotoğrafı birkaç sayfa göster (yana kaydırma hissi)
    const int photoCount = 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceDark.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: profil fotoğrafı, kullanıcı adı, süre
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                  backgroundImage: post.userAvatarUrl != null
                      ? NetworkImage(post.userAvatarUrl!)
                      : null,
                  child: post.userAvatarUrl == null
                      ? Icon(LucideIcons.user, size: 20, color: AppColors.primaryAccent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '@${post.userHandle}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  post.timeAgo ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Medya: yana kaydırılabilir fotoğraflar (Instagram carousel gibi)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                itemCount: photoCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_kFollowingCardImageRadius),
                        child: Image.network(
                          post.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Konum: sade metin (blur yok)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: AppColors.primaryAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.locationTag,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Add to My Map
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onAddToMap();
                },
                icon: const Icon(LucideIcons.mapPin, size: 18),
                label: const Text('Add to My Map'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.surfaceDark,
        child: Icon(LucideIcons.imageOff, size: 48, color: AppColors.textSecondary),
      );
}

/// Tab 2: Explore — MasonryGridView, "✨ Curated by Gemini" badge.
class _ExploreTab extends StatelessWidget {
  const _ExploreTab({
    required this.onPeek,
    required this.onAddToMap,
  });

  final void Function({
    required String heroTag,
    required String imageUrl,
    required String title,
    required String description,
    double? lat,
    double? lng,
  }) onPeek;
  final void Function(BuildContext) onAddToMap;

  @override
  Widget build(BuildContext context) {
    final pins = HomeFeedRepository.getExplore();
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        final height = 180.0 + (index % 3) * 36.0;
        return SizedBox(
          height: height,
          child: _ExploreCard(
            pin: pin,
            onTap: () => onPeek(
              heroTag: 'explore_${pin.id}',
              imageUrl: pin.imageUrl,
              title: pin.locationLabel,
              description: 'AI-recommended spot. ${pin.curatedByGemini ? "Curated by Gemini." : ""}',
              lat: pin.lat,
              lng: pin.lng,
            ),
            onAddToMap: () => onAddToMap(context),
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: (45 * index).ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 320.ms, delay: (45 * index).ms, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.pin,
    required this.onTap,
    required this.onAddToMap,
  });

  final ExplorePin pin;
  final VoidCallback onTap;
  final VoidCallback onAddToMap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              Hero(
                tag: 'explore_${pin.id}',
                child: Image.network(
                  pin.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              ),
              if (pin.curatedByGemini)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black54,
                      border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Curated by Gemini',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pin.locationLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onAddToMap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.mapPin, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceDark,
        child: Icon(LucideIcons.imageOff, size: 40, color: AppColors.textSecondary),
      );
}

/// Tab 3: Local — 2-column symmetric grid, distance indicator.
class _LocalTab extends StatelessWidget {
  const _LocalTab({
    required this.onPeek,
    required this.onAddToMap,
  });

  final void Function({
    required String heroTag,
    required String imageUrl,
    required String title,
    required String description,
    double? lat,
    double? lng,
  }) onPeek;
  final void Function(BuildContext) onAddToMap;

  @override
  Widget build(BuildContext context) {
    final pins = HomeFeedRepository.getLocal();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        return _LocalCard(
          pin: pin,
          onTap: () => onPeek(
            heroTag: 'local_${pin.id}',
            imageUrl: pin.imageUrl,
            title: pin.title,
            description: '${pin.distanceKm}. Popular in Istanbul.',
            lat: pin.lat,
            lng: pin.lng,
          ),
          onAddToMap: () => onAddToMap(context),
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: (50 * index).ms)
            .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), duration: 320.ms, delay: (50 * index).ms, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _LocalCard extends StatelessWidget {
  const _LocalCard({
    required this.pin,
    required this.onTap,
    required this.onAddToMap,
  });

  final LocalPin pin;
  final VoidCallback onTap;
  final VoidCallback onAddToMap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              Hero(
                tag: 'local_${pin.id}',
                child: Image.network(
                  pin.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black54,
                  ),
                  child: Text(
                    pin.distanceKm,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onAddToMap,
                          icon: const Icon(LucideIcons.mapPin, size: 14),
                          label: const Text('Add to Map'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceDark,
        child: Icon(LucideIcons.imageOff, size: 40, color: AppColors.textSecondary),
      );
}

/// Peek View: Hero image, description, View on Map button.
class _PeekView extends StatelessWidget {
  const _PeekView({
    required this.heroTag,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.lat,
    this.lng,
  });

  final String heroTag;
  final String imageUrl;
  final String title;
  final String description;
  final double? lat;
  final double? lng;

  Future<void> _viewOnMap(BuildContext context) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: AppColors.surfaceDark.withValues(alpha: 0.96),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceDark,
                                child: Icon(LucideIcons.imageOff, size: 48, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _viewOnMap(context);
                        },
                        icon: const Icon(LucideIcons.mapPin, size: 20),
                        label: const Text('View on Map'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success overlay: growing pin icon animation.
class _AddToMapSuccessOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(
              LucideIcons.mapPin,
              size: 64,
              color: AppColors.primaryAccent,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              )
              .then()
              .shake(hz: 2, duration: 200.ms, delay: 100.ms),
          const SizedBox(height: 20),
          Text(
            'Added to your map!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 250.ms),
        ],
      ),
    );
  }
}
