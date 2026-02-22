import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Large glassmorphic area for "Paste Link or Upload Screenshot" with
/// breathing neon glow and subtle shimmer.
class MagicDropZone extends StatelessWidget {
  const MagicDropZone({
    super.key,
    this.onTap,
    this.onLinkPaste,
  });

  final VoidCallback? onTap;
  final ValueChanged<String>? onLinkPaste;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _AnimatedGlowBorder(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AppTheme.glassBlurSigma, sigmaY: AppTheme.glassBlurSigma),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: AppTheme.glassBorderOpacity),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.link,
                      size: 40,
                      color: AppColors.primaryAccent.withValues(alpha: 0.9),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .shimmer(duration: 2800.ms, color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Paste Link or Upload Screenshot',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TikTok • Instagram',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a container with an animated gradient border that
/// "breathes" (opacity pulse) and shimmers.
class _AnimatedGlowBorder extends StatefulWidget {
  const _AnimatedGlowBorder({required this.child});

  final Widget child;

  @override
  State<_AnimatedGlowBorder> createState() => _AnimatedGlowBorderState();
}

class _AnimatedGlowBorderState extends State<_AnimatedGlowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _breathing = Tween<double>(begin: 0.25, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathing,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: _breathing.value * 0.4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.secondaryAccent.withValues(alpha: _breathing.value * 0.15),
                blurRadius: 30,
                spreadRadius: -4,
              ),
            ],
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAccent.withValues(alpha: _breathing.value),
                const Color(0xFF00D4FF).withValues(alpha: _breathing.value * 0.6),
                AppColors.secondaryAccent.withValues(alpha: _breathing.value * 0.5),
                AppColors.primaryAccent.withValues(alpha: _breathing.value),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    )
        .animate()
        .shimmer(
          duration: 3200.ms,
          color: AppColors.primaryAccent.withValues(alpha: 0.08),
        )
        .then()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut);
  }
}
