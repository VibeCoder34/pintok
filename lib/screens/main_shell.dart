import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/mock_location.dart';
import '../models/saved_place.dart';
import '../models/collection_model.dart';
import 'library_view.dart';
import '../providers/saved_places_provider.dart';
import '../services/ai_service.dart';
import '../services/apify_service.dart';
import '../services/auth_service.dart';
import '../services/google_places_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analysis_overlay.dart';
import 'map_screen.dart';

/// Root shell: bottom nav with Map | AI Nucleus | Library and scale transition.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _collectionsVersion = 0;
  int _libraryRefreshKey = 0;
  AnalyzedSpot? _previewSpot;
  MockLocation? _previewLocation;
  Uint8List? _previewImageBytes;
  MockLocation? _focusLocationForMap;
  bool _showAiOverlay = false;
  String? _previewProfessionalPhotoUrl;
  bool _previewProfessionalPhotoLoading = false;
  bool _isLinkAnalysisInProgress = false;
  String? _linkAnalysisStatusMessage;

  void _setPreview(AnalyzedSpot spot, MockLocation location, List<int>? imageBytes) {
    setState(() {
      _previewSpot = spot;
      _previewLocation = location;
      _previewImageBytes = imageBytes != null ? Uint8List.fromList(imageBytes) : null;
      _previewProfessionalPhotoUrl = null;
      _previewProfessionalPhotoLoading = true;
      _currentIndex = 0;
    });
    GooglePlacesService().getPlacePhoto(spot.name, location.lat, location.lng).then((url) {
      if (!mounted) return;
      setState(() {
        _previewProfessionalPhotoUrl = url;
        _previewProfessionalPhotoLoading = false;
      });
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _previewProfessionalPhotoUrl = null;
          _previewProfessionalPhotoLoading = false;
        });
      }
    });
  }

  void _clearPreview() {
    setState(() {
      _previewSpot = null;
      _previewLocation = null;
      _previewImageBytes = null;
      _previewProfessionalPhotoUrl = null;
      _previewProfessionalPhotoLoading = false;
    });
  }

  void _confirmPreview(MockLocation location, CollectionModel? collection) {
    final spot = _previewSpot;
    if (spot != null) {
      context.read<SavedPlacesProvider>().add(SavedPlace(
        location: location,
        spot: spot,
        imageBytes: _previewImageBytes,
        collectionId: collection?.id,
      ));
    }
    setState(() {
      _previewSpot = null;
      _previewLocation = null;
      _previewImageBytes = null;
      _previewProfessionalPhotoUrl = null;
      _previewProfessionalPhotoLoading = false;
    });
  }

  void _clearMapFocus() {
    setState(() => _focusLocationForMap = null);
  }

  /// Returns true if user has AI fuel left; false if exhausted (and shows dialog).
  Future<bool> _checkAiFuel(BuildContext context) async {
    final quota = await SupabaseService().getAiScanQuota();
    final count = quota['ai_scans_count'] ?? 0;
    final limit = quota['ai_scans_limit'];
    if (limit != null && count >= limit) {
      if (context.mounted) _showFuelExhaustedDialog(context);
      return false;
    }
    return true;
  }

  void _showFuelExhaustedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            Icon(LucideIcons.flame, color: AppColors.primaryAccent, size: 24),
            const SizedBox(width: 10),
            const Text('Fuel Exhausted'),
          ],
        ),
        content: const Text(
          'You\'ve used all your AI scans for now. Upgrade to Explorer for more scans, or check back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaces = context.watch<SavedPlacesProvider>();
    final userPinnedLocations = savedPlaces.locations;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
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
                ? _MapExplorerTab(
                    key: ValueKey('map_$_collectionsVersion'),
                    userPinnedLocations: userPinnedLocations,
                    previewSpot: _previewSpot,
                    previewLocation: _previewLocation,
                    previewProfessionalPhotoUrl: _previewProfessionalPhotoUrl,
                    previewProfessionalPhotoLoading: _previewProfessionalPhotoLoading,
                    isLinkAnalysisInProgress: _isLinkAnalysisInProgress,
                    linkAnalysisStatusMessage: _linkAnalysisStatusMessage,
                    focusLocation: _focusLocationForMap,
                    onFocusHandled: _clearMapFocus,
                    onConfirmPreview: _previewLocation != null
                        ? (collection) =>
                            _confirmPreview(_previewLocation!, collection)
                        : null,
                    onDiscardPreview: _clearPreview,
                  )
                : LibraryView(
                    key: const ValueKey('library'),
                    refreshTrigger: _libraryRefreshKey,
                    onCollectionsChanged: () {
                      setState(() => _collectionsVersion++);
                    },
                  ),
          ),
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: TextButton.icon(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                  label: Text(
                    'Çıkış (Test)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showAiOverlay
                ? _AiInputOverlay(
                    key: const ValueKey('ai-overlay'),
                    onClose: () {
                      setState(() => _showAiOverlay = false);
                    },
                    onScanPhoto: () {
                      setState(() => _showAiOverlay = false);
                      _openAIScreen(context);
                    },
                    onAnalyzeLink: (url) {
                      setState(() => _showAiOverlay = false);
                      _handleLinkAnalysis(context, url);
                    },
                    isAnalyzingLink: _isLinkAnalysisInProgress,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(userPinnedLocations),
    );
  }

  Future<void> _handleLinkAnalysis(BuildContext context, String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a valid Instagram or TikTok link.'),
        ),
      );
      return;
    }

    final lower = trimmedUrl.toLowerCase();
    // tiktok.com covers v.tiktok.com, www.tiktok.com, vm.tiktok.com, etc.
    final isTikTok = lower.contains('tiktok.com');
    final isInstagram = lower.contains('instagram.com');

    if (!isTikTok && !isInstagram) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a valid Instagram or TikTok link.'),
        ),
      );
      return;
    }

    final hasFuel = await _checkAiFuel(context);
    if (!hasFuel || !context.mounted) return;

    final aiService = AiService();
    final apify = ApifyService();

    setState(() {
      _isLinkAnalysisInProgress = true;
      _linkAnalysisStatusMessage = isTikTok
          ? 'Analyzing TikTok video...'
          : 'Analyzing Instagram post...';
      _previewSpot = null;
      _previewLocation = null;
      _previewImageBytes = null;
      _previewProfessionalPhotoUrl = null;
      _previewProfessionalPhotoLoading = false;
      _currentIndex = 0;
    });

    if (!context.mounted) return;

    Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: AppColors.background,
        pageBuilder: (_, __, ___) => AnalysisOverlayScreen(
          imageProvider: null,
          runAnalysis: () async {
            final result = isTikTok
                ? await apify.scrapeTikTok(trimmedUrl)
                : await apify.scrapeInstagram(trimmedUrl);
            if (result == null || result.caption.trim().isEmpty) {
              return null;
            }
            return aiService.analyzeCaption(
              result.caption,
              locationHint: result.locationName,
            );
          },
          imageBytes: null,
          onPreviewReady: (spot, loc, _) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            setState(() {
              _isLinkAnalysisInProgress = false;
              _linkAnalysisStatusMessage = null;
            });
            _setPreview(spot, loc, null);
          },
          onError: () {
            if (context.mounted) {
              Navigator.of(context).pop();
              setState(() {
                _isLinkAnalysisInProgress = false;
                _linkAnalysisStatusMessage = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTikTok
                        ? 'TikTok analysis failed. Please try a different video link.'
                        : 'We couldn\'t analyze this link. Please try another Instagram or TikTok URL.',
                  ),
                ),
              );
            }
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAIScreen(BuildContext context) async {
    final hasFuel = await _checkAiFuel(context);
    if (!hasFuel || !context.mounted) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null || !context.mounted) return;

    final imageBytes = await xFile.readAsBytes();
    final imageProvider = MemoryImage(imageBytes);
    final aiService = AiService();

    if (!context.mounted) return;
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: AppColors.background,
        pageBuilder: (_, __, ___) => AnalysisOverlayScreen(
          imageProvider: imageProvider,
          runAnalysis: () => aiService.analyzeImage(xFile),
          imageBytes: imageBytes,
          onPreviewReady: (spot, loc, bytes) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            _setPreview(spot, loc, bytes);
          },
          onError: () {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis failed. Please try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(List<MockLocation> userPinnedLocations) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTabTap: (i) {
          setState(() {
            _currentIndex = i;
            if (i == 1) _libraryRefreshKey++;
          });
        },
        onAINucleusTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _showAiOverlay = true);
        },
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}

/// Map Explorer tab: Map + FAB to open upload flow.
class _MapExplorerTab extends StatelessWidget {
  const _MapExplorerTab({
    super.key,
    required this.userPinnedLocations,
    required this.previewSpot,
    required this.previewLocation,
    required this.previewProfessionalPhotoUrl,
    required this.previewProfessionalPhotoLoading,
    required this.isLinkAnalysisInProgress,
    required this.linkAnalysisStatusMessage,
    required this.focusLocation,
    required this.onFocusHandled,
    required this.onConfirmPreview,
    required this.onDiscardPreview,
  });

  final List<MockLocation> userPinnedLocations;
  final AnalyzedSpot? previewSpot;
  final MockLocation? previewLocation;
  final String? previewProfessionalPhotoUrl;
  final bool previewProfessionalPhotoLoading;
  final bool isLinkAnalysisInProgress;
  final String? linkAnalysisStatusMessage;
  final MockLocation? focusLocation;
  final VoidCallback? onFocusHandled;
  final void Function(CollectionModel collection)? onConfirmPreview;
  final VoidCallback? onDiscardPreview;

  @override
  Widget build(BuildContext context) {
    return MapScreen(
      userPinnedLocations: userPinnedLocations,
      previewSpot: previewSpot,
      previewLocation: previewLocation,
      previewProfessionalPhotoUrl: previewProfessionalPhotoUrl,
      previewProfessionalPhotoLoading: previewProfessionalPhotoLoading,
      isLinkAnalysisInProgress: isLinkAnalysisInProgress,
      linkAnalysisStatusMessage: linkAnalysisStatusMessage,
      focusLocation: focusLocation,
      onFocusHandled: onFocusHandled,
      onConfirmPreview: onConfirmPreview,
      onDiscardPreview: onDiscardPreview,
    );
  }
}

/// Glassmorphic floating dock: Map | AI Nucleus | My Journey.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTabTap,
    required this.onAINucleusTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onAINucleusTap;

  @override
  Widget build(BuildContext context) {
    const double barHeight = 65;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? Colors.grey[900]!.withOpacity(0.8)
        : Colors.white.withOpacity(0.8);

    return SizedBox(
      height: barHeight + 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Floating pill TabBar positioned above the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15,
                    sigmaY: 15,
                  ),
                  child: Container(
                    height: barHeight,
                    width: size.width * 0.85,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Item 1: Map
                        IconButton(
                          icon: Icon(
                            LucideIcons.compass,
                            size: 26,
                            color: currentIndex == 0
                                ? AppColors.primaryAccent
                                : Colors.white54,
                          ),
                          splashRadius: 26,
                          onPressed: () => onTabTap(0),
                        ),
                        // Item 2: AI Nucleus
                        _AINucleusButton(onTap: onAINucleusTap),
                        // Item 3: Profile
                        IconButton(
                          icon: Icon(
                            LucideIcons.user,
                            size: 26,
                            color: currentIndex == 1
                                ? AppColors.primaryAccent
                                : Colors.white54,
                          ),
                          splashRadius: 26,
                          onPressed: () => onTabTap(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Center button: gradient (deep purple → electric blue), glow, sparkles icon, press scale.
class _AINucleusButton extends StatefulWidget {
  const _AINucleusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AINucleusButton> createState() => _AINucleusButtonState();
}

class _AINucleusButtonState extends State<_AINucleusButton> {
  bool _pressed = false;

  static const _gradientStart = AppColors.primaryAccent; // Brand orange
  static const _gradientEnd = Color(0xFFF8724E);         // Lighter brand tint

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_pressed ? 0.92 : 1.0),
        transformAlignment: Alignment.center,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [_gradientStart, _gradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: const Icon(
          LucideIcons.scan,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AiInputOverlay extends StatefulWidget {
  const _AiInputOverlay({
    super.key,
    required this.onClose,
    required this.onScanPhoto,
    required this.onAnalyzeLink,
    required this.isAnalyzingLink,
  });

  final VoidCallback onClose;
  final VoidCallback onScanPhoto;
  final ValueChanged<String> onAnalyzeLink;
  final bool isAnalyzingLink;

  @override
  State<_AiInputOverlay> createState() => _AiInputOverlayState();
}

class _AiInputOverlayState extends State<_AiInputOverlay> {
  bool _showLinkInput = false;
  final TextEditingController _linkController = TextEditingController();
  bool _prefilledFromClipboard = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _enterLinkMode() async {
    HapticFeedback.selectionClick();
    setState(() => _showLinkInput = true);

    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.contains('http')) {
      setState(() {
        _linkController.text = text.trim();
        _prefilledFromClipboard = true;
      });
    }
  }

  void _onAnalyzeLink() {
    if (_linkController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    widget.onClose();
    widget.onAnalyzeLink(_linkController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = 16.0 + mediaQuery.padding.bottom + 90.0; // leave space for TabBar

    return IgnorePointer(
      ignoring: false,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: 1,
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'What would you like to do?',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 22),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  onPressed: widget.onClose,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _showLinkInput
                                    ? _buildLinkInputView()
                                    : _buildOptionsView(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsView() {
    return Column(
      key: const ValueKey('options'),
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onScanPhoto();
            },
            child: _OptionCard(
              icon: Icons.photo_camera_back_rounded,
              title: 'Scan an Image',
              subtitle: 'From your gallery or camera. AI analyzes visual clues.',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5E35B1),
                  Color(0xFF2196F3),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GestureDetector(
            onTap: _enterLinkMode,
            child: _OptionCard(
              icon: Icons.link_rounded,
              title: 'Paste a Link',
              subtitle: 'Instagram, TikTok, Pinterest URLs. AI extracts location.',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEC407A),
                  Color(0xFF42A5F5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkInputView() {
    return Column(
      key: const ValueKey('link-input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paste URL',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Instagram, TikTok, Pinterest – we\'ll try to pinpoint the place.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _linkController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.primaryAccent,
                decoration: InputDecoration(
                  hintText: 'Paste URL here...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_prefilledFromClipboard) ...[
          const SizedBox(height: 8),
          Text(
            'Pasted from clipboard',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _linkController.text.trim().isEmpty
                ? null
                : _onAnalyzeLink,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              shadowColor: AppColors.primaryAccent.withValues(alpha: 0.7),
              elevation: 6,
            ),
            child: const Text('Analyze Link'),
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    backgroundBlendMode: BlendMode.softLight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

