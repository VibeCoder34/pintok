import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/collection_model.dart';
import '../models/library_models.dart';
import '../services/supabase_service.dart';
import 'create_collection_sheet.dart';
import 'edit_profile_view.dart';
import 'collection_detail_view.dart';
import 'settings_view.dart';
import '../theme/app_theme.dart';

/// Data loaded for the library profile header (username, bio, real counts).
class _LibraryProfileData {
  const _LibraryProfileData({
    this.profile,
    required this.pinsCount,
    required this.collectionsCount,
  });

  final Map<String, dynamic>? profile;
  final int pinsCount;
  final int collectionsCount;

  String get username =>
      (profile?['username'] as String?)?.trim().isNotEmpty == true
          ? (profile?['username'] as String).trim()
          : (profile?['full_name'] as String?)?.trim().isNotEmpty == true
              ? (profile?['full_name'] as String).trim()
              : 'traveler';

  String get bio =>
      (profile?['bio'] as String?)?.trim().isNotEmpty == true
          ? (profile?['bio'] as String).trim()
          : 'Curating your personal journey archive.';

  String? get avatarUrl => profile?['avatar_url'] as String?;
}

/// Traveler Profile: personal archive of collections with profile header.
class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    this.onCollectionsChanged,
  });

  /// Called when user creates a new collection so Map tab can refresh filter chips.
  final VoidCallback? onCollectionsChanged;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late List<Collection> _collections;
  final SupabaseService _supabase = SupabaseService();
  bool _loading = true;
  Future<_LibraryProfileData>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _collections = <Collection>[];
    _loadCollections();
    _profileFuture = _loadProfileData();
  }

  Future<_LibraryProfileData> _loadProfileData() async {
    final profile = await _supabase.getCurrentUserProfile();
    final pinsCount = await _supabase.getMyPinsCount();
    final collectionsCount = await _supabase.getMyCollectionsCount();
    return _LibraryProfileData(
      profile: profile,
      pinsCount: pinsCount,
      collectionsCount: collectionsCount,
    );
  }

  Future<void> _loadCollections() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase.getCollections();
      // Map backend collections to UI model. Pin counts / privacy are not yet
      // stored in the database, so we default them.
      final mapped = rows
          .map(
            (c) => Collection(
              id: c.id,
              name: c.name,
              pinCount: 0,
              coverImageUrl: '',
              isPrivate: false,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _collections = mapped;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load journeys. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
      _collections.insert(
        0,
        Collection(
          id: created.id,
          name: created.name,
          pinCount: 0,
          coverImageUrl: '',
          isPrivate: false,
        ),
      );
      _profileFuture = _loadProfileData();
    });
    widget.onCollectionsChanged?.call();
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey Created!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collections = _collections;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted overlay over the same background as Map view
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<_LibraryProfileData>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _LibraryProfileHeaderShimmer();
                      }
                      final data = snapshot.data ?? _LibraryProfileData(
                        profile: null,
                        pinsCount: 0,
                        collectionsCount: 0,
                      );
                      return _LibraryProfileHeader(data: data);
                    },
                  ),
                  const SizedBox(height: 22),
                  if (_loading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                    ),
                  if (!_loading && collections.isEmpty)
                    _EmptyLibraryState(onCreateTap: _onCreateCollectionTapped)
                  else if (!_loading)
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 3 / 4,
                        ),
                        itemCount: collections.length + 1, // +1 for "Create"
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _CreateCollectionCard(
                              onTap: _onCreateCollectionTapped,
                            )
                                .animate()
                                .fadeIn(
                                  duration: 320.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  duration: 320.ms,
                                  curve: Curves.easeOutCubic,
                                );
                          }
                          final collection = collections[index - 1];
                          return _CollectionCard(
                            collection: collection,
                            onDetailResult: (result) {
                              if (result == null) return;
                              if (result['deleted'] == true) {
                                setState(() => _collections.removeWhere((c) => c.id == collection.id));
                                widget.onCollectionsChanged?.call();
                              }
                              if (result['updated'] != null) {
                                setState(() {
                                  final i = _collections.indexWhere((c) => c.id == collection.id);
                                  if (i >= 0) {
                                    final c = _collections[i];
                                    _collections[i] = Collection(id: c.id, name: result['updated'] as String, pinCount: c.pinCount, coverImageUrl: c.coverImageUrl, isPrivate: c.isPrivate);
                                  }
                                });
                                widget.onCollectionsChanged?.call();
                              }
                            },
                          )
                              .animate()
                              .fadeIn(
                                duration: 320.ms,
                                delay: (40 * index).ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(
                                begin: 0.06,
                                end: 0,
                                duration: 360.ms,
                                delay: (40 * index).ms,
                                curve: Curves.easeOutCubic,
                              );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder while profile and stats are loading.
class _LibraryProfileHeaderShimmer extends StatelessWidget {
  const _LibraryProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.06));
  }
}

/// Profile header with real username, bio, and counts from Supabase.
class _LibraryProfileHeader extends StatelessWidget {
  const _LibraryProfileHeader({required this.data});

  final _LibraryProfileData data;

  @override
  Widget build(BuildContext context) {
    final username = data.username.startsWith('@') ? data.username : '@${data.username}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _GlowAvatar(avatarUrl: data.avatarUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SettingsIconButton(),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileView(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TravelStatsRow(
          pins: data.pinsCount,
          collections: data.collectionsCount,
          impact: 0,
        ),
      ],
    );
  }
}

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
            radius: 24,
            backgroundColor: AppColors.surfaceDark,
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? Icon(LucideIcons.user, size: 26, color: AppColors.textSecondary.withValues(alpha: 0.8))
                : null,
          ),
        ),
      ),
    );
  }
}

class _SettingsIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const SettingsView(),
                transitionsBuilder: (_, animation, __, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelStatsRow extends StatelessWidget {
  const _TravelStatsRow({
    required this.pins,
    required this.collections,
    required this.impact,
  });

  final int pins;
  final int collections;
  final int impact;

  @override
  Widget build(BuildContext context) {
    Widget buildItem(String label, String value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildItem('Pins', '$pins'),
              _StatsDivider(),
              buildItem('Collections', '$collections'),
              _StatsDivider(),
              buildItem('Impact', '$impact'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.24),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.explore,
                      size: 40,
                      color: AppColors.primaryAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your journey starts here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a collection to start saving pins, or scan a photo later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCreateTap();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create journey'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class _CreateCollectionCard extends StatelessWidget {
  const _CreateCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 26,
                    ),
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
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.onDetailResult,
  });

  final Collection collection;
  final void Function(Map<String, dynamic>? result) onDetailResult;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(
                  builder: (_) => CollectionDetailView(collection: collection),
                ),
              ).then(onDetailResult);
            },
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          collection.coverImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            );
                          },
                          errorBuilder: (context, _, __) {
                            return Container(
                              color: Colors.black.withValues(alpha: 0.25),
                              child: Icon(
                                Icons.photo,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 32,
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            collection.isPrivate ? Icons.lock : Icons.public,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${collection.pinCount} Pins',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
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


