import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/library_models.dart';
import '../models/pin_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class CollectionDetailView extends StatefulWidget {
  const CollectionDetailView({
    super.key,
    required this.collection,
  });

  final Collection collection;

  @override
  State<CollectionDetailView> createState() => _CollectionDetailViewState();
}

class _CollectionDetailViewState extends State<CollectionDetailView> {
  final SupabaseService _supabase = SupabaseService();
  late Future<List<PinModel>> _pinsFuture;
  late Collection _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _pinsFuture = _supabase.getPins(_collection.id);
  }

  Future<void> _refreshPins() async {
    setState(() {
      _pinsFuture = _supabase.getPins(_collection.id);
    });
  }

  static List<SavedPin> _pinsToSavedPins(List<PinModel> pins, String collectionId) {
    return pins
        .map(
          (p) => SavedPin(
            id: p.id,
            name: p.title,
            locationName: (p.metadata?['city'] as String?) ?? '',
            imageUrl: p.imageUrl ?? '',
            collectionId: collectionId,
            description: p.description ?? '',
            dateAdded: p.createdAt,
            latitude: p.latitude,
            longitude: p.longitude,
          ),
        )
        .toList();
  }

  void _showCollectionMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Edit Name'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog(ctx);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                    title: Text('Delete Collection', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDeleteCollectionConfirm(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: _collection.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Edit collection name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Collection name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _supabase.updateCollection(_collection.id, name);
                if (!mounted) return;
                setState(() => _collection = Collection(
                  id: _collection.id,
                  name: name,
                  pinCount: _collection.pinCount,
                  coverImageUrl: _collection.coverImageUrl,
                  isPrivate: _collection.isPrivate,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection updated'), behavior: SnackBarBehavior.floating),
                );
                Navigator.of(context).pop({'updated': name});
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCollectionConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete collection?'),
        content: const Text(
          'All pins in this collection will be deleted. This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase.deleteCollection(_collection.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection deleted'), behavior: SnackBarBehavior.floating),
                );
                Navigator.of(context).pop({'deleted': true});
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PinModel>>(
      future: _pinsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Text(
                'Could not load pins.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        final pinModels = snapshot.data ?? [];
        final pins = _pinsToSavedPins(pinModels, _collection.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _CollectionMapAppBar(
                collection: _collection,
                pins: pins,
                onMoreTap: _showCollectionMenu,
              ),
              SliverToBoxAdapter(
                child: _CollectionMetaRow(collection: _collection, pinCount: pins.length),
              ),
              SliverList.separated(
                itemCount: pins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final pin = pins[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 12 : 0,
                      16,
                      index == pins.length - 1 ? 24 : 0,
                    ),
                    child: _PinPostCard(
                      pin: pin,
                      currentCollectionId: _collection.id,
                      onDeleted: () async {
                        await _refreshPins();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pin deleted'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      onMoved: () async {
                        await _refreshPins();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pin moved'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CollectionMapAppBar extends StatelessWidget {
  const _CollectionMapAppBar({
    required this.collection,
    required this.pins,
    required this.onMoreTap,
  });

  final Collection collection;
  final List<SavedPin> pins;
  final VoidCallback onMoreTap;

  LatLng get _center {
    if (pins.isEmpty) return LatLng(48.8566, 2.3522);
    final avgLat = pins.map((p) => p.latitude).reduce((a, b) => a + b) / pins.length;
    final avgLng = pins.map((p) => p.longitude).reduce((a, b) => a + b) / pins.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: Colors.white,
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        collection.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded),
          color: Colors.white.withOpacity(0.9),
          onPressed: () {
            // Future share flow.
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          color: Colors.white.withOpacity(0.9),
          onPressed: onMoreTap,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MiniMapHeader(center: _center, pins: pins),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.2, 0.7, 1.0],
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

class _MiniMapHeader extends StatelessWidget {
  const _MiniMapHeader({
    required this.center,
    required this.pins,
  });

  final LatLng center;
  final List<SavedPin> pins;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.pintok',
              retinaMode: true,
            ),
            MarkerLayer(
              markers: pins
                  .map(
                    (p) => Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryAccent.withValues(alpha: 0.7),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionMetaRow extends StatelessWidget {
  const _CollectionMetaRow({
    required this.collection,
    required this.pinCount,
  });

  final Collection collection;
  final int pinCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            collection.isPrivate ? Icons.lock : Icons.public,
            size: 18,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Text(
            collection.isPrivate ? 'Private Collection' : 'Public Collection',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$pinCount Pins',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPostCard extends StatelessWidget {
  const _PinPostCard({
    required this.pin,
    this.currentCollectionId,
    this.onDeleted,
    this.onMoved,
  });

  final SavedPin pin;
  final String? currentCollectionId;
  final VoidCallback? onDeleted;
  final VoidCallback? onMoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActions = onDeleted != null || onMoved != null;

    return GestureDetector(
      onLongPress: hasActions
          ? () => _showPinMenu(context)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: pin.imageUrl.isEmpty
                            ? Container(
                                color: Colors.black.withOpacity(0.25),
                                child: const Icon(
                                  Icons.photo,
                                  size: 32,
                                  color: Colors.white70,
                                ),
                              )
                            : Image.network(
                                pin.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.black.withOpacity(0.25),
                                  );
                                },
                                errorBuilder: (context, _, __) {
                                  return Container(
                                    color: Colors.black.withOpacity(0.25),
                                    child: const Icon(
                                      Icons.photo,
                                      size: 32,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (pin.imageUrl.isNotEmpty)
                        Positioned(
                          left: 10,
                          bottom: 8,
                          child: Text(
                            'Photos by Google',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pin.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (hasActions)
                            IconButton(
                              icon: Icon(Icons.more_horiz_rounded, size: 20, color: Colors.white.withOpacity(0.8)),
                              onPressed: () => _showPinMenu(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            )
                          else
                            const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Would open this location on the map.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.navigation_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pin.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(pin.dateAdded),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Notes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showPinMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onMoved != null && currentCollectionId != null)
                    ListTile(
                      leading: const Icon(Icons.folder_rounded),
                      title: const Text('Move to another Collection'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showMoveToCollectionSheet(context, ctx);
                      },
                    ),
                  if (onDeleted != null)
                    ListTile(
                      leading: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                      title: Text('Delete Pin', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDeletePinConfirm(context, ctx);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeletePinConfirm(BuildContext context, BuildContext sheetContext) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete pin?'),
        content: const Text('This pin will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService().deletePin(pin.id);
                onDeleted?.call();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete pin'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoveToCollectionSheet(BuildContext context, BuildContext sheetContext) async {
    final supabase = SupabaseService();
    final collections = await supabase.getCollections();
    final other = currentCollectionId == null
        ? collections
        : collections.where((c) => c.id != currentCollectionId).toList();
    if (!context.mounted) return;
    if (other.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other collection to move to'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Move to collection',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...other.map((c) => ListTile(
                    title: Text(c.name),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await supabase.updatePin(pin.id, {'collection_id': c.id});
                        onMoved?.call();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to move pin'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

