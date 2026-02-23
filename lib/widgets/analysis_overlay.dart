import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/mock_location.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

/// UI state for the analysis overlay — reactive to business logic results.
enum AnalysisOverlayState {
  analyzing,
  success,
  error,
}

/// Full-screen overlay shown when a user uploads a screenshot.
/// On success, geocodes and calls [onPreviewReady]; confirmation happens on the map.
class AnalysisOverlay extends StatefulWidget {
  const AnalysisOverlay({
    super.key,
    required this.background,
    required this.runAnalysis,
    required this.onPreviewReady,
    required this.onError,
  });

  final Widget background;
  final Future<AnalyzedSpot?> Function() runAnalysis;
  /// Called with (spot, geocoded location) so the app can show map preview + confirmation card.
  final void Function(AnalyzedSpot spot, MockLocation location) onPreviewReady;
  final VoidCallback onError;

  @override
  State<AnalysisOverlay> createState() => _AnalysisOverlayState();
}

class _AnalysisOverlayState extends State<AnalysisOverlay>
    with TickerProviderStateMixin {
  AnalysisOverlayState _state = AnalysisOverlayState.analyzing;
  AnalyzedSpot? _result;

  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  int _statusIndex = 0;

  static const _statusMessages = [
    'Identifying landmarks...',
    'Fetching local details...',
    'Pinning on map...',
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final spot = await widget.runAnalysis();
    if (!mounted) return;
    if (spot == null) {
      setState(() => _state = AnalysisOverlayState.error);
      return;
    }
    setState(() {
      _result = spot;
      _state = AnalysisOverlayState.success;
    });
    final loc = await AiService.geocode(spot);
    if (!mounted) return;
    if (loc == null) {
      setState(() => _state = AnalysisOverlayState.error);
      return;
    }
    widget.onPreviewReady(spot, loc);
  }

  void _dismissError() {
    widget.onError();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
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
          _buildVignette(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _state == AnalysisOverlayState.analyzing
                ? _buildScanningState()
                : _state == AnalysisOverlayState.success
                    ? _buildSuccessState()
                    : _buildErrorState(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLayer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + 0.012 * _pulseController.value;
          final opacity = 0.92 + 0.08 * (1 - _pulseController.value).abs();
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          );
        },
        child: widget.background,
      ),
    );
  }

  Widget _buildScanningState() {
    return Stack(
      key: const ValueKey('scanning'),
      fit: StackFit.expand,
      children: [
        _buildGlowingScanLine(),
        _buildStatusPanel(),
      ],
    );
  }

  Widget _buildGlowingScanLine() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, _) {
        final t = _scanLineController.value;
        final top = 0.12 + 0.76 * t;
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.sizeOf(context).height * top - 2,
          child: IgnorePointer(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primaryAccent.withValues(alpha: 0.4),
                    AppColors.primaryAccent,
                    AppColors.secondaryAccent.withValues(alpha: 0.9),
                    AppColors.primaryAccent,
                    AppColors.primaryAccent.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.5, 0.6, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                    blurRadius: 24,
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

  Widget _buildStatusPanel() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 140,
      child: _StatusMessagePanel(
        message: _statusMessages[_statusIndex % _statusMessages.length],
        interval: const Duration(milliseconds: 800),
        onTick: () {
          if (_state == AnalysisOverlayState.analyzing && mounted) {
            setState(() => _statusIndex++);
          }
        },
      ),
    );
  }

  Widget _buildSuccessState() {
    final spot = _result!;
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.mapPin,
                          size: 28,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          spot.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (spot.category != null && spot.category!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.primaryAccent.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            spot.category!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (spot.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      spot.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 350.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
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
              'We couldn\'t identify this place',
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
            const SizedBox(height: 10),
            Text(
              'Try another photo for better results',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            )
                .animate()
                .fadeIn(delay: 220.ms, duration: 280.ms),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _dismissError,
              icon: const Icon(LucideIcons.imagePlus, size: 18),
              label: const Text('Try Another Photo'),
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

  Widget _buildVignette() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.65),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
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
    required this.onPreviewReady,
    required this.onError,
  });

  final ImageProvider? imageProvider;
  final Future<AnalyzedSpot?> Function() runAnalysis;
  final void Function(AnalyzedSpot spot, MockLocation location) onPreviewReady;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    final background = imageProvider != null
        ? Image(image: imageProvider!, fit: BoxFit.cover)
        : _buildPlaceholderBackground();
    return AnalysisOverlay(
      background: background,
      runAnalysis: runAnalysis,
      onPreviewReady: onPreviewReady,
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

/// Panel that shows a rotating status message on an interval (decoupled from parent state).
class _StatusMessagePanel extends StatefulWidget {
  const _StatusMessagePanel({
    required this.message,
    required this.interval,
    required this.onTick,
  });

  final String message;
  final Duration interval;
  final VoidCallback onTick;

  @override
  State<_StatusMessagePanel> createState() => _StatusMessagePanelState();
}

class _StatusMessagePanelState extends State<_StatusMessagePanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => widget.onTick());
  }

  @override
  void didUpdateWidget(covariant _StatusMessagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _timer = Timer.periodic(widget.interval, (_) => widget.onTick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAccent.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
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
