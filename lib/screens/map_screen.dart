import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/mock_location.dart';
import '../models/collection_model.dart';
import '../models/pin_model.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_pin.dart';
import 'create_collection_sheet.dart';

/// CartoDB Dark Matter — matches PinTok midnight theme.
const _cartoDarkUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const _cartoSubdomains = ['a', 'b', 'c', 'd'];

/// Paris center for initial map view.
final _parisCenter = LatLng(48.8566, 2.3522);
const _defaultZoom = 14.0;
const _flyToZoom = 15.2;
const _flyToDuration = Duration(milliseconds: 650);

/// Discovery map: real FlutterMap, dark tiles, custom markers, bottom carousel.
/// When [previewLocation] is set, shows a ghost marker and "Found it!" confirmation card.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.userPinnedLocations = const [],
    this.previewSpot,
    this.previewLocation,
    this.previewProfessionalPhotoUrl,
    this.previewProfessionalPhotoLoading = false,
    this.isLinkAnalysisInProgress = false,
    this.linkAnalysisStatusMessage,
    this.focusLocation,
    this.onFocusHandled,
    this.onConfirmPreview,
    this.onDiscardPreview,
  });

  final List<MockLocation> userPinnedLocations;
  final AnalyzedSpot? previewSpot;
  final MockLocation? previewLocation;
  /// High-resolution photo URL from Google Places (used in discovery card and saved to pin).
  final String? previewProfessionalPhotoUrl;
  /// True while fetching professional photo (show "Fetching professional visuals...").
  final bool previewProfessionalPhotoLoading;
  /// True while we are analyzing a pasted social link (Apify + Gemini + geocode).
  /// Used to show the DiscoveryRevealCard in a loading state before the final spot is known.
  final bool isLinkAnalysisInProgress;
  /// Optional status text shown while a social link is being analyzed.
  final String? linkAnalysisStatusMessage;
  /// When set (e.g. from Saved), fly to this location and then call [onFocusHandled].
  final MockLocation? focusLocation;
  final VoidCallback? onFocusHandled;
  final void Function(CollectionModel collection)? onConfirmPreview;
  final VoidCallback? onDiscardPreview;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  late final AnimatedMapController _mapController;
  int _selectedIndex = 0;
  /// Index in _locations of the marker that should play the pin-drop animation.
  int? _pinDropIndex;
  String? _activeCollectionId;
  String? _selectedPinId;
  String? _lastFocusedCollectionId;

  final SupabaseService _supabase = SupabaseService();
  Future<List<PinModel>>? _pinsFuture;
  Future<List<CollectionModel>>? _collectionsFuture;

  List<MockLocation> get _locations => [...widget.userPinnedLocations];

  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(
      vsync: this,
      duration: _flyToDuration,
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
    _pinsFuture = _loadPins();
    _collectionsFuture = _supabase.getCollections();
  }

  Future<List<PinModel>> _loadPins() async {
    return _supabase.getPins(_activeCollectionId);
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fly to preview location when it appears.
    if (widget.previewLocation != null &&
        oldWidget.previewLocation != widget.previewLocation) {
      _flyToLocation(widget.previewLocation!);
      HapticFeedback.lightImpact();
      HapticFeedback.lightImpact();
    }
    // Fly to focus location when requested from Saved screen.
    if (widget.focusLocation != null && widget.focusLocation != oldWidget.focusLocation) {
      _flyToLocation(widget.focusLocation!);
      widget.onFocusHandled?.call();
    }
    final prevCount = oldWidget.userPinnedLocations.length;
    final newCount = widget.userPinnedLocations.length;
    if (newCount > prevCount && newCount > 0) {
      final newLoc = widget.userPinnedLocations.last;
      final index = _locations.length - 1;
      setState(() {
        _pinDropIndex = index;
        _selectedIndex = index;
      });
      _flyToLocation(newLoc);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _pinDropIndex = null);
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPinTapped(int index) {
    setState(() => _selectedIndex = index);
    _flyToLocation(_locations[index]);
  }

  void _flyToLocation(MockLocation loc) {
    _mapController.animateTo(
      dest: LatLng(loc.lat, loc.lng),
      zoom: _flyToZoom,
      duration: _flyToDuration,
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
  }

  void _resetMapToInitial() {
    _mapController.animateTo(
      dest: _parisCenter,
      zoom: _defaultZoom,
      duration: _flyToDuration,
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
  }

  void _focusOnPinModels(List<PinModel> pins) {
    if (pins.isEmpty) return;
    if (pins.length == 1) {
      final p = pins.first;
      _mapController.animateTo(
        dest: LatLng(p.latitude, p.longitude),
        zoom: _flyToZoom,
        duration: _flyToDuration,
        curve: Curves.easeInOutCubic,
        cancelPreviousAnimations: true,
      );
      return;
    }

    // For multiple pins, center roughly between them and zoom out a bit
    // so that all are likely visible.
    final avgLat = pins.map((p) => p.latitude).reduce((a, b) => a + b) / pins.length;
    final avgLng = pins.map((p) => p.longitude).reduce((a, b) => a + b) / pins.length;
    _mapController.animateTo(
      dest: LatLng(avgLat, avgLng),
      zoom: _defaultZoom - 1.5,
      duration: _flyToDuration,
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final showPreview = widget.previewSpot != null && widget.previewLocation != null;
    final showCard = showPreview || widget.isLinkAnalysisInProgress;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(size),
          if (!showCard) _buildExploreSheet(),
          if (showCard) _buildFoundItCard(size),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: FutureBuilder<List<CollectionModel>>(
              future: _collectionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _MapFilterChipsShimmer();
                }
                final collections =
                    snapshot.data ?? const <CollectionModel>[];
                return _MapFilterChips(
                  collections: collections,
                  activeCollectionId: _activeCollectionId,
                  onFilterChanged: (id) {
                    setState(() {
                      _activeCollectionId = id;
                      _pinsFuture = _loadPins();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundItCard(Size size) {
    final isLoadingOnly =
        widget.isLinkAnalysisInProgress && widget.previewSpot == null;
    final spot = widget.previewSpot;
    final loadingTitle =
        widget.linkAnalysisStatusMessage ?? 'Analyzing social link & finding location...';
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DiscoveryCardThumbnail(
                            professionalPhotoUrl: widget.previewProfessionalPhotoUrl,
                            professionalPhotoLoading:
                                isLoadingOnly || widget.previewProfessionalPhotoLoading,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoadingOnly ? loadingTitle : (spot?.name ?? ''),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!isLoadingOnly && spot != null && spot.city.isNotEmpty)
                                  Text(
                                    spot.city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              widget.onDiscardPreview?.call();
                              _resetMapToInitial();
                            },
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (!isLoadingOnly &&
                          (widget.previewProfessionalPhotoUrl != null ||
                              widget.previewProfessionalPhotoLoading)) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Photos by Google',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (!isLoadingOnly &&
                          spot != null &&
                          spot.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          spot.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (!isLoadingOnly)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryAccent,
                                      AppColors.primaryAccent.withValues(alpha: 0.85),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAccent
                                          .withValues(alpha: 0.55),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed: () => _onAddToMapPressed(),
                                  icon: const Icon(
                                    LucideIcons.bookmarkPlus,
                                    size: 18,
                                  ),
                                  label: const Text('Add to My Journeys'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.25,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutBack,
        );
  }

  Future<void> _onAddToMapPressed() async {
    HapticFeedback.mediumImpact();
    final collections = await SupabaseService().getCollections();
    if (!mounted) return;

    final selected = await showModalBottomSheet<CollectionModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _SaveToCollectionSheet(
          collections: collections,
          onCreateNewTap: () async {
            final created = await showModalBottomSheet<CollectionModel>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const CreateCollectionSheet(),
            );
            return created;
          },
        );
      },
    );
    if (!mounted || selected == null) return;

    if (widget.previewSpot == null || widget.previewLocation == null) {
      return;
    }

    final spot = widget.previewSpot!;
    final loc = widget.previewLocation!;

    final pin = PinModel.forInsert(
      collectionId: selected.id,
      title: spot.name,
      description: spot.description,
      imageUrl: widget.previewProfessionalPhotoUrl,
      latitude: loc.lat,
      longitude: loc.lng,
      metadata: <String, dynamic>{
        'city': spot.city,
        if (spot.category != null) 'category': spot.category,
      },
    );

    try {
      await _supabase.savePin(pin);
      await _supabase.incrementAiScansCount();
      if (!mounted) return;
      setState(() {
        _pinsFuture = _loadPins();
      });
      await _showSavedSuccessOverlay();
      widget.onConfirmPreview?.call(selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showSavedSuccessOverlay() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Saved',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return Center(
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: 0.8 + 0.2 * curved.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black.withValues(alpha: 0.7),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 56,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).timeout(
      const Duration(milliseconds: 900),
      onTimeout: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  Widget _buildMap(Size size) {
    return Positioned.fill(
      child: FlutterMap(
        mapController: _mapController.mapController,
        options: MapOptions(
          initialCenter: _parisCenter,
          initialZoom: _defaultZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onTap: (_, __) {},
        ),
        children: [
          TileLayer(
            urlTemplate: _cartoDarkUrl,
            subdomains: _cartoSubdomains,
            userAgentPackageName: 'com.keremugurlu.pintok',
            retinaMode: true,
          ),
          if (widget.previewLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.previewLocation!.lat, widget.previewLocation!.lng),
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: MapPin(
                    location: widget.previewLocation!,
                    size: 44,
                    isSelected: false,
                    isGhost: true,
                  ),
                ),
              ],
            ),
          // User pins (from camera flow) – tap to focus
          MarkerLayer(
            markers: List.generate(widget.userPinnedLocations.length, (i) {
              final loc = widget.userPinnedLocations[i];
              return Marker(
                point: LatLng(loc.lat, loc.lng),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _onPinTapped(i),
                  child: MapPin(
                    location: loc,
                    size: 44,
                    isSelected: _selectedIndex == i,
                    animateDrop: _pinDropIndex == i,
                  ),
                ),
              );
            }),
          ),
          // Persistent pins from Supabase, filterable by collection
          FutureBuilder<List<PinModel>>(
            future: _pinsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final pins = snapshot.data!;
              if (_activeCollectionId != null &&
                  _activeCollectionId != _lastFocusedCollectionId &&
                  pins.isNotEmpty) {
                // After changing the collection filter, automatically focus
                // the map on the pins for that collection.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _focusOnPinModels(pins);
                });
                _lastFocusedCollectionId = _activeCollectionId;
              }
              return MarkerLayer(
                markers: pins.map((pin) {
                  final loc = MockLocation(
                    id: pin.id,
                    name: pin.title,
                    city: (pin.metadata?['city'] as String?) ?? '',
                    lat: pin.latitude,
                    lng: pin.longitude,
                    imageUrl: pin.imageUrl,
                    thumbnailColor: AppColors.primaryAccent,
                  );
                  return Marker(
                    point: LatLng(pin.latitude, pin.longitude),
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPinId = pin.id);
                        _flyToLocation(loc);
                      },
                      child: MapPin(
                        location: loc,
                        size: 44,
                        isSelected: _selectedPinId == pin.id,
                        animateDrop: false,
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildExploreSheet() {
    return const SizedBox.shrink();
  }
}

/// Shimmer placeholder while collection chips are loading.
class _MapFilterChipsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ShimmerPill(width: 72),
          const SizedBox(width: 8),
          _ShimmerPill(width: 88),
          const SizedBox(width: 8),
          _ShimmerPill(width: 96),
          const SizedBox(width: 8),
          _ShimmerPill(width: 80),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.08));
  }
}

class _ShimmerPill extends StatelessWidget {
  const _ShimmerPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

class _MapFilterChips extends StatelessWidget {
  const _MapFilterChips({
    required this.collections,
    required this.activeCollectionId,
    required this.onFilterChanged,
  });

  final List<CollectionModel> collections;
  final String? activeCollectionId;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChipPill(
            label: 'All Pins',
            selected: activeCollectionId == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          for (final c in collections) ...[
            _FilterChipPill(
              label: c.name,
              selected: activeCollectionId == c.id,
              onTap: () => onFilterChanged(c.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: selected
                  ? AppColors.primaryAccent
                  : Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                color: selected
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail in the discovery "Found it!" card: loading state, professional photo, or placeholder.
class _DiscoveryCardThumbnail extends StatelessWidget {
  const _DiscoveryCardThumbnail({
    required this.professionalPhotoUrl,
    required this.professionalPhotoLoading,
  });

  final String? professionalPhotoUrl;
  final bool professionalPhotoLoading;

  @override
  Widget build(BuildContext context) {
    const double size = 54;
    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: professionalPhotoLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Fetching professional visuals...',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            )
          : professionalPhotoUrl != null && professionalPhotoUrl!.isNotEmpty
              ? Image.network(
                  professionalPhotoUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Icon(
                    LucideIcons.image,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                )
              : Icon(
                  LucideIcons.image,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
    );
    return container;
  }
}

class _SaveToCollectionSheet extends StatelessWidget {
  const _SaveToCollectionSheet({
    required this.collections,
    required this.onCreateNewTap,
  });

  final List<CollectionModel> collections;
  final Future<CollectionModel?> Function() onCreateNewTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: Colors.black.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
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
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Save to Collection',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  collections.isEmpty
                      ? 'Create your first journey to save this pin.'
                      : 'Choose where this new pin should live.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _CreateNewCollectionRow(onCreateNewTap: onCreateNewTap),
                const SizedBox(height: 12),
                Flexible(
                  child: collections.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: collections.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = collections[index];
                            return _CollectionRow(
                              collection: c,
                              onTap: () {
                                Navigator.of(context).pop<CollectionModel>(c);
                              },
                            );
                          },
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

class _CreateNewCollectionRow extends StatelessWidget {
  const _CreateNewCollectionRow({required this.onCreateNewTap});

  final Future<CollectionModel?> Function() onCreateNewTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final created = await onCreateNewTap();
        if (context.mounted && created != null) {
          Navigator.of(context).pop<CollectionModel>(created);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent,
                    AppColors.secondaryAccent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Create New Collection',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.collection,
    required this.onTap,
  });

  final CollectionModel collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
