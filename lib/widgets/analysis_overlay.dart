import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/ai_service.dart';
import '../theme/app_theme.dart';

/// Full-screen overlay shown when a user uploads a screenshot.
/// Runs [runAnalysis], shows laser + log lines, then success or error.
class AnalysisOverlay extends StatefulWidget {
  const AnalysisOverlay({
    super.key,
    required this.background,
    required this.runAnalysis,
    required this.onComplete,
    required this.onError,
  });

  /// The full-screen background (e.g. Image from file, or placeholder Widget).
  final Widget background;
  /// Called when overlay is shown; overlay waits for this to complete.
  final Future<AnalyzedSpot?> Function() runAnalysis;
  final void Function(AnalyzedSpot spot) onComplete;
  final VoidCallback onError;

  @override
  State<AnalysisOverlay> createState() => _AnalysisOverlayState();
}

class _AnalysisOverlayState extends State<AnalysisOverlay>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late AnimationController _phaseController;
  int _visibleLogIndex = 0;
  List<String> _logMessages = const [
    'Extracting location...',
    "Identifying place...",
    'Checking coordinates...',
    'Match found.',
  ];
  bool _showSuccess = false;
  bool _showError = false;
  AnalyzedSpot? _result;

  @override
  void initState() {
    super.initState();
    _visibleLogIndex = 1; // Show "Extracting location..." while analysis runs
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    final spot = await widget.runAnalysis();
    if (!mounted) return;
    if (spot == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() {
      _result = spot;
      _logMessages = [
        'Extracting location...',
        "Identifying '${spot.name}'...",
        'Checking ${spot.city} coordinates...',
        'Match found.',
      ];
    });
    _phaseController.forward();
    _phaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _runLogSequence();
      }
    });
  }

  Future<void> _runLogSequence() async {
    for (var i = 0; i < _logMessages.length; i++) {
      if (!mounted) return;
      setState(() => _visibleLogIndex = i + 1);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _showSuccessAndTransition();
  }

  Future<void> _showSuccessAndTransition() async {
    setState(() => _showSuccess = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final spot = _result!;
    widget.onComplete(spot);
  }

  void _dismissError() {
    widget.onError();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageLayer(),
          if (!_showError) _buildLaserLine(),
          _buildVignette(),
          if (_showError) _buildErrorState(),
          if (!_showSuccess && !_showError) _buildLogPanel(),
          if (_showSuccess) _buildSuccessState(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                LucideIcons.mapPinOff,
                size: 48,
                color: AppColors.textSecondary,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            Text(
              'Could not find spot, try another screenshot',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _dismissError,
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.9),
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 250.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLayer() {
    return Positioned.fill(child: widget.background);
  }

  Widget _buildLaserLine() {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, _) {
        final top = 0.15 + 0.7 * _laserController.value;
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.sizeOf(context).height * top - 1,
          child: IgnorePointer(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primaryAccent.withValues(alpha: 0.3),
                    AppColors.primaryAccent,
                    AppColors.secondaryAccent.withValues(alpha: 0.8),
                    AppColors.primaryAccent,
                    AppColors.primaryAccent.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVignette() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_visibleLogIndex, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _logMessages[i],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideX(begin: -0.05, end: 0, duration: 350.ms);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.primaryAccent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.check,
              size: 56,
              color: AppColors.primaryAccent,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 200.ms),
          const SizedBox(height: 24),
          Text(
            'Location pinned',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

/// Helper screen to push the overlay; uses a gradient placeholder when no image.
class AnalysisOverlayScreen extends StatelessWidget {
  const AnalysisOverlayScreen({
    super.key,
    this.imageProvider,
    required this.runAnalysis,
    required this.onComplete,
    required this.onError,
  });

  final ImageProvider? imageProvider;
  final Future<AnalyzedSpot?> Function() runAnalysis;
  final void Function(AnalyzedSpot spot) onComplete;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    final background = imageProvider != null
        ? Image(image: imageProvider!, fit: BoxFit.cover)
        : _buildPlaceholderBackground();
    return AnalysisOverlay(
      background: background,
      runAnalysis: runAnalysis,
      onComplete: onComplete,
      onError: onError,
    );
  }

  static Widget _buildPlaceholderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            AppColors.surfaceDark,
            AppColors.background,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _PlaceholderGridPainter(),
      ),
    );
  }
}

class _PlaceholderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const step = 40.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
