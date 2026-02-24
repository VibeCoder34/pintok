import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/mock_location.dart';
import '../models/saved_place.dart';
import '../providers/saved_places_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_reveal_route.dart';
import 'home_feed_view.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_view.dart';
import 'settings_view.dart';

/// Root shell: bottom nav with Home (feed) | Map Explorer | My Journey and scale transition.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  AnalyzedSpot? _previewSpot;
  MockLocation? _previewLocation;
  Uint8List? _previewImageBytes;
  MockLocation? _focusLocationForMap;

  void _goToMapTab() {
    setState(() => _currentIndex = 1);
  }

  void _setPreview(AnalyzedSpot spot, MockLocation location, List<int>? imageBytes) {
    setState(() {
      _previewSpot = spot;
      _previewLocation = location;
      _previewImageBytes = imageBytes != null ? Uint8List.fromList(imageBytes) : null;
      _currentIndex = 1;
    });
  }

  void _clearPreview() {
    setState(() {
      _previewSpot = null;
      _previewLocation = null;
      _previewImageBytes = null;
    });
  }

  void _confirmPreview(MockLocation location) {
    final spot = _previewSpot;
    if (spot != null) {
      context.read<SavedPlacesProvider>().add(SavedPlace(
        location: location,
        spot: spot,
        imageBytes: _previewImageBytes,
      ));
    }
    setState(() {
      _previewSpot = null;
      _previewLocation = null;
      _previewImageBytes = null;
    });
  }

  void _clearMapFocus() {
    setState(() => _focusLocationForMap = null);
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaces = context.watch<SavedPlacesProvider>();
    final userPinnedLocations = savedPlaces.locations;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _currentIndex == 0
            ? const HomeFeedView(key: ValueKey('home'))
            : _currentIndex == 1
                ? _MapExplorerTab(
                    key: const ValueKey('map'),
                    userPinnedLocations: userPinnedLocations,
                    previewSpot: _previewSpot,
                    previewLocation: _previewLocation,
                    focusLocation: _focusLocationForMap,
                    onFocusHandled: _clearMapFocus,
                    onConfirmPreview: _previewLocation != null
                        ? () => _confirmPreview(_previewLocation!)
                        : null,
                    onDiscardPreview: _clearPreview,
                    setPreview: _setPreview,
                    goToMapTab: _goToMapTab,
                  )
                : _currentIndex == 2
                    ? const ProfileView(key: ValueKey('profile'))
                    : const SettingsView(key: ValueKey('settings')),
      ),
      bottomNavigationBar: _buildBottomNav(userPinnedLocations),
    );
  }

  void _openAIScreen(BuildContext context, Rect revealFromRect, List<MockLocation> userPinnedLocations) {
    Navigator.of(context).push<void>(
      CircularRevealRoute(
        revealFromRect: revealFromRect,
        child: HomeScreen(
          goToDiscoverTab: () {
            Navigator.of(context).pop();
            _goToMapTab();
          },
          userPinnedLocations: userPinnedLocations,
          setPreview: (spot, loc, bytes) {
            Navigator.of(context).pop();
            _setPreview(spot, loc, bytes);
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav(List<MockLocation> userPinnedLocations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTabTap: (i) => setState(() => _currentIndex = i),
        onAINucleusTap: (rect) {
          HapticFeedback.mediumImpact();
          _openAIScreen(context, rect, userPinnedLocations);
        },
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}

/// Map Explorer tab: Map + FAB to open upload flow (HomeScreen).
class _MapExplorerTab extends StatelessWidget {
  const _MapExplorerTab({
    super.key,
    required this.userPinnedLocations,
    required this.previewSpot,
    required this.previewLocation,
    required this.focusLocation,
    required this.onFocusHandled,
    required this.onConfirmPreview,
    required this.onDiscardPreview,
    required this.setPreview,
    required this.goToMapTab,
  });

  final List<MockLocation> userPinnedLocations;
  final AnalyzedSpot? previewSpot;
  final MockLocation? previewLocation;
  final MockLocation? focusLocation;
  final VoidCallback? onFocusHandled;
  final VoidCallback? onConfirmPreview;
  final VoidCallback? onDiscardPreview;
  final void Function(AnalyzedSpot, MockLocation, List<int>?) setPreview;
  final VoidCallback goToMapTab;

  @override
  Widget build(BuildContext context) {
    return MapScreen(
      userPinnedLocations: userPinnedLocations,
      previewSpot: previewSpot,
      previewLocation: previewLocation,
      focusLocation: focusLocation,
      onFocusHandled: onFocusHandled,
      onConfirmPreview: onConfirmPreview,
      onDiscardPreview: onDiscardPreview,
    );
  }
}

/// Glassmorphic floating dock: blur 15, radius 30, thin border. Home | Map | AI Nucleus | Profile | Settings.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTabTap,
    required this.onAINucleusTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final void Function(Rect globalRect) onAINucleusTap;

  static const double _barRadius = 30;
  static const double _barBorderWidth = 0.5;
  static const double _glassBlur = 15;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_barRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _glassBlur, sigmaY: _glassBlur),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 58),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_barRadius),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: _barBorderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: LucideIcons.house,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTabTap(0),
              ),
              _NavItem(
                icon: LucideIcons.compass,
                label: 'Map',
                isSelected: currentIndex == 1,
                onTap: () => onTabTap(1),
              ),
              _AINucleusButton(onTap: onAINucleusTap),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () => onTabTap(2),
              ),
              _NavItem(
                icon: LucideIcons.settings,
                label: 'Settings',
                isSelected: currentIndex == 3,
                onTap: () => onTabTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Center button: gradient (deep purple → electric blue), glow, sparkles icon, press scale.
class _AINucleusButton extends StatefulWidget {
  const _AINucleusButton({required this.onTap});

  final void Function(Rect globalRect) onTap;

  @override
  State<_AINucleusButton> createState() => _AINucleusButtonState();
}

class _AINucleusButtonState extends State<_AINucleusButton> {
  final GlobalKey _key = GlobalKey();
  bool _pressed = false;

  static const _gradientStart = Color(0xFF5E35B1); // Deep purple
  static const _gradientEnd = Color(0xFF2196F3);   // Electric blue

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  void _handleTap() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    final rect = box != null
        ? Rect.fromPoints(
            box.localToGlobal(Offset.zero),
            box.localToGlobal(box.size.bottomRight(Offset.zero)),
          )
        : Rect.zero;
    widget.onTap(rect);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      child: Container(
        key: _key,
        margin: const EdgeInsets.only(bottom: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_pressed ? 0.88 : 1.0),
          transformAlignment: Alignment.center,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradientStart, _gradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: _gradientEnd.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _gradientStart.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: const Icon(
            LucideIcons.sparkles,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
