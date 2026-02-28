import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/collection.dart';
import '../models/saved_place_pin.dart';
import '../theme/app_theme.dart';

const _cartoDarkUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const _cartoSubdomains = ['a', 'b', 'c', 'd'];

/// Detail screen for one collection: pins grid, metadata, and in Profile mode "Add to My Map" on each pin.
class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collection,
    this.isProfileView = false,
    this.onShareCollection,
  });

  final Collection collection;
  /// When true, show as visitor: "Add to My Map" on each pin.
  final bool isProfileView;
  final VoidCallback? onShareCollection;

  @override
  Widget build(BuildContext context) {
    final pins = pinsForCollection(collection);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _CollectionAppBar(
            collection: collection,
            isProfileView: isProfileView,
            onShare: onShareCollection ?? () => _showShareSheet(context, collection),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final pin = pins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CollectionPinCard(
                      place: pin,
                      isProfileView: isProfileView,
                      onTap: () => _openPinDetail(context, pin),
                      onAddToMap: isProfileView
                          ? () {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${pin.name} to your map'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : null,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 280.ms, delay: (40 * index).ms)
                      .slideY(begin: 0.04, end: 0, duration: 320.ms, delay: (40 * index).ms, curve: Curves.easeOutCubic);
                },
                childCount: pins.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPinDetail(BuildContext context, SavedPlacePin place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailBottomSheet(place: place, showAddToMap: isProfileView),
    );
  }

  void _showShareSheet(BuildContext context, Collection c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareCollectionSheet(collection: c),
    );
  }
}

class _CollectionAppBar extends StatelessWidget {
  const _CollectionAppBar({
    required this.collection,
    required this.isProfileView,
    required this.onShare,
  });

  final Collection collection;
  final bool isProfileView;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final coverUrl = coverImageForCollection(collection);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.of(context).pop(),
        color: AppColors.textPrimary,
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.share2),
          onPressed: onShare,
          color: AppColors.textPrimary,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: coverUrl != null && coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
        title: Text(
          collection.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, 1)),
              Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(LucideIcons.folder, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
      ),
    );
  }
}

/// Pin card in collection: image, name, metadata badges (source + privacy), optional "Add to My Map".
class _CollectionPinCard extends StatelessWidget {
  const _CollectionPinCard({
    required this.place,
    required this.isProfileView,
    required this.onTap,
    this.onAddToMap,
  });

  final SavedPlacePin place;
  final bool isProfileView;
  final VoidCallback onTap;
  final VoidCallback? onAddToMap;

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
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceDark,
                    child: Icon(LucideIcons.imageOff, size: 40, color: AppColors.textSecondary),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _MetadataChip(
                            icon: place.isUserUploadedPhoto ? LucideIcons.camera : LucideIcons.mapPin,
                            label: place.isUserUploadedPhoto ? 'Your photo' : 'Location',
                          ),
                          const SizedBox(width: 8),
                          if (place.isPrivate)
                            _MetadataChip(
                              icon: LucideIcons.lock,
                              label: 'Private',
                            )
                          else
                            _MetadataChip(
                              icon: LucideIcons.globe,
                              label: 'On profile',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${place.city}, ${place.country}',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (onAddToMap != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onAddToMap,
                            icon: const Icon(LucideIcons.mapPin, size: 18),
                            label: const Text('Add to My Map'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Reusable detail bottom sheet; [showAddToMap] for profile/visitor view.
/// Shows metadata (User Uploaded Photo vs Location, Keep Private vs Share on Profile) and optional toggle.
class _DetailBottomSheet extends StatefulWidget {
  const _DetailBottomSheet({required this.place, this.showAddToMap = false});

  final SavedPlacePin place;
  final bool showAddToMap;

  @override
  State<_DetailBottomSheet> createState() => _DetailBottomSheetState();
}

class _DetailBottomSheetState extends State<_DetailBottomSheet> {
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.place.isPrivate;
  }

  SavedPlacePin get place => widget.place;
  bool get showAddToMap => widget.showAddToMap;

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: AppColors.surfaceDark.withValues(alpha: 0.95),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            place.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceDark,
                              child: Icon(LucideIcons.imageOff, size: 48, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MetadataChip(
                            icon: place.isUserUploadedPhoto ? LucideIcons.camera : LucideIcons.mapPin,
                            label: place.isUserUploadedPhoto ? 'User uploaded photo' : 'Location coordinates',
                          ),
                          const SizedBox(width: 8),
                          _MetadataChip(
                            icon: _isPrivate ? LucideIcons.lock : LucideIcons.globe,
                            label: _isPrivate ? 'Keep private' : 'Share on profile',
                          ),
                        ],
                      ),
                      if (!showAddToMap) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Share on profile',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Switch(
                              value: !_isPrivate,
                              onChanged: (value) {
                                setState(() => _isPrivate = !value);
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? 'Pin shared on profile' : 'Pin kept private'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              activeColor: AppColors.primaryAccent,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 16, color: AppColors.primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            '${place.city}, ${place.country}',
                            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        place.description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(place.latitude, place.longitude),
                              initialZoom: 14,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: _cartoDarkUrl,
                                subdomains: _cartoSubdomains,
                                userAgentPackageName: 'com.keremugurlu.pintok',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(place.latitude, place.longitude),
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: Icon(LucideIcons.mapPin, color: AppColors.primaryAccent, size: 28),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (showAddToMap)
                        FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${place.name} to your map'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.mapPin, size: 20),
                          label: const Text('Add to My Map'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      if (showAddToMap) const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _openGoogleMaps();
                        },
                        icon: const Icon(LucideIcons.externalLink, size: 20),
                        label: const Text('Get Directions'),
                        style: FilledButton.styleFrom(
                          backgroundColor: showAddToMap ? Colors.white24 : AppColors.primaryAccent,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

/// Bottom sheet: unique share link + QR code for the collection.
class ShareCollectionSheet extends StatelessWidget {
  const ShareCollectionSheet({super.key, required this.collection});

  final Collection collection;

  String get _shareUrl {
    final slug = collection.shareSlug ?? '${collection.id}-${collection.name.hashCode.abs()}';
    return 'https://pintok.app/c/$slug';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: AppColors.surfaceDark.withValues(alpha: 0.98),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share collection',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                collection.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _shareUrl,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unique link',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                _shareUrl,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primaryAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.copy, size: 18),
                label: const Text('Copy link'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
