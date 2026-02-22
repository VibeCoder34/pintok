import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/mock_location.dart';
import '../theme/app_theme.dart';
import '../widgets/map_pin.dart';

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
/// Swiping the carousel flies the map to the corresponding marker.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.userPinnedLocations = const []});

  final List<MockLocation> userPinnedLocations;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final PageController _carouselController =
      PageController(viewportFraction: 0.88);
  late final AnimatedMapController _mapController;
  int _selectedIndex = 0;

  List<MockLocation> get _locations => [
    ...mockDiscoverLocations,
    ...widget.userPinnedLocations,
  ];

  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(
      vsync: this,
      duration: _flyToDuration,
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onCarouselPageChanged(int index) {
    setState(() => _selectedIndex = index);
    _flyToLocation(_locations[index]);
  }

  void _onPinTapped(int index) {
    _carouselController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(size),
          _buildBottomCarousel(size),
        ],
      ),
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
            userAgentPackageName: 'com.example.pintok',
            retinaMode: true,
          ),
          MarkerLayer(
            markers: List.generate(_locations.length, (i) {
              final loc = _locations[i];
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
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCarousel(Size size) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Discover',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _carouselController,
                onPageChanged: _onCarouselPageChanged,
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _CarouselCard(
                      location: _locations[index],
                      isSelected: _selectedIndex == index,
                      index: index,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.location,
    required this.isSelected,
    required this.index,
  });

  final MockLocation location;
  final bool isSelected;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = location.thumbnailColor ?? AppColors.primaryAccent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: isSelected ? 0.12 : 0.06),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: location.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          location.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        LucideIcons.mapPin,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.city,
                      style: const TextStyle(
                        fontSize: 13,
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
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .then(delay: (50 * index).ms);
  }
}
