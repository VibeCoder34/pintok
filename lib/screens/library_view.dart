import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_model.dart';
import '../models/library_models.dart';
import '../services/supabase_service.dart';
import '../widgets/profile_avatar.dart';
import 'create_collection_sheet.dart';
import 'edit_profile_view.dart';
import 'collection_detail_view.dart';
import 'settings_view.dart';
import '../theme/app_theme.dart';
import '../widgets/fuel_gauge.dart';

/// Data loaded for the library profile header (display name, bio, real counts, AI fuel).
class _LibraryProfileData {
  const _LibraryProfileData({
    this.profile,
    required this.pinsCount,
    required this.collectionsCount,
    required this.displayName,
    this.aiScansUsed = 0,
    this.aiScansLimit,
  });

  final Map<String, dynamic>? profile;
  final int pinsCount;
  final int collectionsCount;
  final String displayName;
  final int aiScansUsed;
  final int? aiScansLimit;

  String get bio =>
      (profile?['bio'] as String?)?.trim().isNotEmpty == true
          ? (profile?['bio'] as String).trim()
          : 'Curating your personal journey archive.';

  String? get avatarUrl => profile?['avatar_url'] as String?;
  String? get avatarKey => profile?['avatar_key'] as String?;
}

/// Traveler Profile: personal archive of collections with profile header.
class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    this.onCollectionsChanged,
    this.refreshTrigger = 0,
  });

  /// Called when user creates a new collection so Map tab can refresh filter chips.
  final VoidCallback? onCollectionsChanged;
  /// When this value changes (e.g. when user switches to this tab), profile/quota is refetched.
  final int refreshTrigger;

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

  @override
  void didUpdateWidget(covariant LibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      setState(() => _profileFuture = _loadProfileData());
    }
  }

  Future<_LibraryProfileData> _loadProfileData() async {
    try {
      // Single profile fetch includes ai_scans_count/ai_scans_limit (select *). No separate quota call.
      final results = await Future.wait<Object?>([
        _supabase.getCurrentUserProfile(),
        _supabase.getMyPinsCount(),
        _supabase.getMyCollectionsCount(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => <Object?>[null, 0, 0],
      );

      final profile = results[0] as Map<String, dynamic>?;
      final pinsCount = results[1] as int;
      final collectionsCount = results[2] as int;

      final aiScansUsed = _parseIntFromProfile(profile, 'ai_scans_count') ?? 0;
      final aiScansLimit = _parseIntFromProfile(profile, 'ai_scans_limit');

      final displayName = _supabase.getDisplayName(profile);

      return _LibraryProfileData(
        profile: profile,
        pinsCount: pinsCount,
        collectionsCount: collectionsCount,
        displayName: displayName,
        aiScansUsed: aiScansUsed,
        aiScansLimit: aiScansLimit,
      );
    } catch (_) {
      return _LibraryProfileData(
        profile: null,
        pinsCount: 0,
        collectionsCount: 0,
        displayName: _supabase.getDisplayName(null),
        aiScansUsed: 0,
        aiScansLimit: null,
      );
    }
  }

  static int? _parseIntFromProfile(Map<String, dynamic>? profile, String key) {
    if (profile == null || !profile.containsKey(key)) return null;
    final v = profile[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  Future<void> _loadCollections() async {
    setState(() => _loading = true);
    try {
      // Load collections, pin counts, and cover images concurrently.
      final collectionsFuture = _supabase.getCollections();
      final pinCountsFuture = _supabase.getPinCountsByCollection();
      final coverImagesFuture = _supabase.getFirstPinImageByCollection();

      final rows = await collectionsFuture;
      final pinCounts = await pinCountsFuture;
      final coverImages = await coverImagesFuture;
      // Prefer collection's explicit cover_image_url; else first pin image.
      final mapped = rows
          .map(
            (c) => Collection(
              id: c.id,
              name: c.name,
              pinCount: pinCounts[c.id] ?? 0,
              coverImageUrl: (c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty)
                  ? c.coverImageUrl!
                  : (coverImages[c.id] ?? ''),
              coverColor: c.coverColor,
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
          coverColor: created.coverColor,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                        displayName: SupabaseService().getDisplayName(null),
                        aiScansUsed: 0,
                        aiScansLimit: null,
                      );
                      return _LibraryProfileHeader(
                        data: data,
                        onAvatarChanged: () {
                          setState(() {
                            _profileFuture = _loadProfileData();
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
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
                              if (result['coverUpdated'] == true) {
                                _loadCollections();
                                widget.onCollectionsChanged?.call();
                              }
                              if (result['updated'] != null) {
                                setState(() {
                                  final i = _collections.indexWhere((c) => c.id == collection.id);
                                  if (i >= 0) {
                                    final c = _collections[i];
                                    _collections[i] = Collection(id: c.id, name: result['updated'] as String, pinCount: c.pinCount, coverImageUrl: c.coverImageUrl, coverColor: c.coverColor);
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

/// Profile header: compact card with avatar, name, scans, actions and stats.
class _LibraryProfileHeader extends StatelessWidget {
  const _LibraryProfileHeader({
    required this.data,
    this.onAvatarChanged,
  });

  final _LibraryProfileData data;
  final VoidCallback? onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final displayName = data.displayName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ProfileAvatar(
                avatarUrl: data.avatarUrl,
                avatarKey: data.avatarKey,
                radius: 20,
                onAvatarChanged: onAvatarChanged,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scans ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  FuelGauge(
                    scansUsed: data.aiScansUsed,
                    scansLimit: data.aiScansLimit,
                    loading: false,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              _ActionChip(
                label: 'Edit Profile',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileView(),
                      fullscreenDialog: true,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              _SettingsIconButton(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${data.pinsCount} Pins · ${data.collectionsCount} Journeys',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tappable chip for header actions.
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.settings_outlined,
            size: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
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

  static Widget _collectionCoverPlaceholder(String? coverColorHex) {
    Color color = AppColors.primaryAccent.withValues(alpha: 0.3);
    if (coverColorHex != null && coverColorHex.isNotEmpty) {
      try {
        final hex = coverColorHex.startsWith('#') ? coverColorHex.substring(1) : coverColorHex;
        if (hex.length >= 6) {
          color = Color(0xFF000000 | int.parse(hex.substring(0, 6), radix: 16));
        }
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
      ),
      child: Icon(
        Icons.map_outlined,
        size: 40,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

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
                        if (collection.coverImageUrl.isNotEmpty)
                          Image.network(
                            collection.coverImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _collectionCoverPlaceholder(collection.coverColor);
                            },
                            errorBuilder: (context, _, __) =>
                                _collectionCoverPlaceholder(collection.coverColor),
                          )
                        else
                          _collectionCoverPlaceholder(collection.coverColor),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


