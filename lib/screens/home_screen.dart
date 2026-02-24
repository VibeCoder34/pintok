import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mock_location.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analysis_overlay.dart';
import '../widgets/location_card.dart';
import '../widgets/magic_drop_zone.dart';

/// Mock data: realistic travel spots for "Pinned Recently" (shown when no user pins yet).
const _recentSpotsFallback = [
  (name: 'Padella', city: 'London'),
  (name: 'La Sagrada Familia', city: 'Barcelona'),
  (name: 'Café de Flore', city: 'Paris'),
  (name: 'Tsukiji Outer Market', city: 'Tokyo'),
  (name: 'Duomo di Milano', city: 'Milan'),
  (name: 'Borough Market', city: 'London'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.goToDiscoverTab,
    this.userPinnedLocations = const [],
    this.setPreview,
  });

  final VoidCallback? goToDiscoverTab;
  final List<MockLocation> userPinnedLocations;
  /// Called when analysis succeeds and we have a geocoded location for map preview. Optional image bytes for archive.
  final void Function(AnalyzedSpot spot, MockLocation location, List<int>? imageBytes)? setPreview;

  /// Recent spots: user-pinned first, then fallback list (up to 6).
  List<({String name, String city})> get _recentSpots {
    final fromUser = userPinnedLocations
        .map((l) => (name: l.name, city: l.city))
        .toList();
    final need = 6 - fromUser.length;
    if (need <= 0) return fromUser.take(6).toList();
    return [...fromUser, ..._recentSpotsFallback.take(need)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 32),
                child: MagicDropZone(
                  onTap: () => _onDropZoneTap(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Pinned Recently',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final spot = _recentSpots[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LocationCard(
                        name: spot.name,
                        city: spot.city,
                        index: index,
                      ),
                    );
                  },
                  childCount: _recentSpots.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _onDropZoneTap(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null || !context.mounted) return;

    final imageFile = xFile;
    final imageBytes = await imageFile.readAsBytes();
    final imageProvider = MemoryImage(imageBytes);
    final aiService = AiService();

    if (!context.mounted) return;
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: AppColors.background,
        pageBuilder: (_, __, ___) => AnalysisOverlayScreen(
          imageProvider: imageProvider,
          runAnalysis: () => aiService.analyzeImage(imageFile),
          imageBytes: imageBytes,
          onPreviewReady: (spot, loc, bytes) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            setPreview?.call(spot, loc, bytes);
            goToDiscoverTab?.call();
          },
          onError: () {
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
        child: Text(
          'PinTok',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
