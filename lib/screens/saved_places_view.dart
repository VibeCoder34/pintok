import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/collection.dart';
import '../theme/app_theme.dart';
import 'collection_detail_screen.dart';

/// Personal Collections: folder grid with cover photos, serif titles, Profile view with "Add to My Map".
class SavedPlacesView extends StatefulWidget {
  const SavedPlacesView({super.key});

  @override
  State<SavedPlacesView> createState() => _SavedPlacesViewState();
}

class _SavedPlacesViewState extends State<SavedPlacesView> {
  /// false = My Collections (owner), true = Profile (visitor view with Add to My Map).
  bool _isProfileView = false;

  List<Collection> get _visibleCollections {
    if (_isProfileView) {
      return mockCollections.where((c) => !c.isPrivate && (c.shareSlug != null && c.shareSlug!.isNotEmpty)).toList();
    }
    return mockCollections;
  }

  @override
  Widget build(BuildContext context) {
    final collections = _visibleCollections;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderWithToggle(
              isProfileView: _isProfileView,
              onToggle: () => setState(() => _isProfileView = !_isProfileView),
            ),
            Expanded(
              child: collections.isEmpty
                  ? _EmptyCollectionsState(isProfileView: _isProfileView)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final c = collections[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _FolderCard(
                            collection: c,
                            isProfileView: _isProfileView,
                            onTap: () => _openCollection(context, c),
                            onShare: () => _showShareSheet(context, c),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 320.ms, delay: (60 * index).ms)
                            .slideY(begin: 0.05, end: 0, duration: 380.ms, delay: (60 * index).ms, curve: Curves.easeOutCubic);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCollection(BuildContext context, Collection c) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => CollectionDetailScreen(
          collection: c,
          isProfileView: _isProfileView,
          onShareCollection: () => _showShareSheet(ctx, c),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, Collection c) {
    Navigator.of(context).pop(); // close detail if open
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareCollectionSheet(collection: c),
    );
  }
}

/// Top bar: title + My Journeys | Profile segment control.
class _HeaderWithToggle extends StatelessWidget {
  const _HeaderWithToggle({
    required this.isProfileView,
    required this.onToggle,
  });

  final bool isProfileView;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text(
            isProfileView ? 'Profile' : 'My Journeys',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Segment(
                      label: 'Mine',
                      isSelected: !isProfileView,
                      onTap: () {
                        if (isProfileView) onToggle();
                      },
                    ),
                    _Segment(
                      label: 'Profile',
                      isSelected: isProfileView,
                      onTap: () {
                        if (!isProfileView) onToggle();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.25) : Colors.transparent,
          border: isSelected ? Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Large folder card: cover photo + serif title (e.g. "Paris 2026" style).
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.collection,
    required this.isProfileView,
    required this.onTap,
    required this.onShare,
  });

  final Collection collection;
  final bool isProfileView;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final coverUrl = coverImageForCollection(collection);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isProfileView && (collection.shareSlug != null))
                        IconButton(
                          onPressed: onShare,
                          icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 22),
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

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(LucideIcons.folder, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
      ),
    );
  }
}

/// Empty state when no journeys (or no shared ones in Profile mode).
class _EmptyCollectionsState extends StatelessWidget {
  const _EmptyCollectionsState({required this.isProfileView});

  final bool isProfileView;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isProfileView ? LucideIcons.users : LucideIcons.folderPlus,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              isProfileView ? 'No shared journeys' : 'No journeys yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isProfileView
                  ? 'Journeys shared on profile will appear here.'
                  : 'Create a journey and add pins to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
