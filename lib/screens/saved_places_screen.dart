import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/mock_location.dart';
import '../models/saved_place.dart';
import '../providers/saved_places_provider.dart';
import '../theme/app_theme.dart';

/// Saved Places archive: grid of cards, search, slide-to-delete, detail modal.
class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({
    super.key,
    this.onFocusOnMap,
  });

  /// Callback to switch to Map tab and center on the given location.
  final void Function(MockLocation? location)? onFocusOnMap;

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchesSearch(SavedPlace place) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.trim().toLowerCase();
    if (place.name.toLowerCase().contains(q)) return true;
    if (place.city.toLowerCase().contains(q)) return true;
    if (place.category != null && place.category!.toLowerCase().contains(q)) return true;
    if (place.description.toLowerCase().contains(q)) return true;
    return false;
  }

  void _openDetailModal(SavedPlace place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailModal(
        place: place,
        onShowOnMap: () {
          Navigator.of(ctx).pop();
          widget.onFocusOnMap?.call(place.location);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedPlacesProvider>();
    final places = provider.places.where(_matchesSearch).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _GlassSearchHeader(
              controller: _searchController,
              focusNode: _searchFocusNode,
              searchQuery: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            Expanded(
              child: places.isEmpty
                  ? _EmptyState(hasPlaces: provider.places.isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return _SavedPlaceCard(
                          place: place,
                          onTap: () => _openDetailModal(place),
                          onDelete: () => provider.remove(place),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (40 * index).ms)
                            .slideY(begin: 0.06, end: 0, duration: 350.ms, delay: (40 * index).ms, curve: Curves.easeOutCubic);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism header with search bar; stays fixed at top while list scrolls.
class _GlassSearchHeader extends StatelessWidget {
  const _GlassSearchHeader({
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or category...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppColors.textSecondary,
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

/// Single saved place card: photo, name, tags. Slide to delete, tap for details.
class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({
    required this.place,
    required this.onTap,
    required this.onDelete,
  });

  final SavedPlace place;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey(place.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.secondaryAccent.withValues(alpha: 0.85),
          ),
          child: Icon(
            LucideIcons.trash2,
            size: 28,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          return true;
        },
        onDismissed: (_) => onDelete(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardImage(place: place),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (place.tags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: place.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.primaryAccent.withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: AppColors.primaryAccent.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.place});

  final SavedPlace place;

  @override
  Widget build(BuildContext context) {
    final color = place.location.thumbnailColor ?? AppColors.primaryAccent;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: place.imageBytes != null && place.imageBytes!.isNotEmpty
          ? Image.memory(
              place.imageBytes!,
              fit: BoxFit.cover,
            )
          : Container(
              color: color,
              child: Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
    );
  }
}

/// Empty state: no places at all vs. no results for search.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasPlaces});

  final bool hasPlaces;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.map,
                    size: 72,
                    color: AppColors.primaryAccent.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 450.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(
              hasPlaces ? 'No results' : 'Your map is a blank canvas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 350.ms),
            const SizedBox(height: 10),
            Text(
              hasPlaces
                  ? 'Try a different search or category.'
                  : 'Upload a photo to start pinning!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
                .animate()
                .fadeIn(delay: 250.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet modal with full Gemini analysis and "Show on Map" action.
class _DetailModal extends StatelessWidget {
  const _DetailModal({
    required this.place,
    required this.onShowOnMap,
  });

  final SavedPlace place;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
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
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.city,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (place.tags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: place.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (place.description.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'From your photo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          place.description,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onShowOnMap();
                        },
                        icon: const Icon(LucideIcons.mapPin, size: 20),
                        label: const Text('Show on Map'),
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
