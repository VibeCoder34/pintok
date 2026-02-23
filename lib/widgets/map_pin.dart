import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/mock_location.dart';
import '../theme/app_theme.dart';

/// Custom map pin: small circular "profile" of the location with neon border.
/// When [animateDrop] is true, the pin animates falling onto the map from above.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.location,
    this.size = 44,
    this.isSelected = false,
    this.animateDrop = false,
    this.isGhost = false,
    this.onTap,
  });

  final MockLocation location;
  final double size;
  final bool isSelected;
  /// When true, plays a one-time drop-from-above animation.
  final bool animateDrop;
  /// When true, shows a semi-transparent temporary/preview marker.
  final bool isGhost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = location.thumbnailColor ?? AppColors.primaryAccent;
    final ghostOpacity = 0.5;
    final borderColor = isGhost
        ? Colors.white.withValues(alpha: 0.5)
        : (isSelected ? AppColors.primaryAccent : Colors.white);
    final shadowColor = isGhost
        ? color.withValues(alpha: 0.25)
        : (isSelected ? AppColors.primaryAccent : color).withValues(alpha: 0.4);
    final pinColor = isGhost ? color.withValues(alpha: ghostOpacity) : color;
    final iconOpacity = isGhost ? 0.8 : 0.9;

    Widget content = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 12,
        height: size + 12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isGhost)
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: isSelected ? 14 : 8,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
              ),
            Container(
              width: size + 6,
              height: size + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isGhost ? 2 : (isSelected ? 3 : 2),
                ),
                boxShadow: isGhost
                    ? null
                    : [
                        BoxShadow(
                          color: (isSelected ? AppColors.primaryAccent : Colors.white).withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
              ),
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pinColor,
                    image: location.imageUrl != null && !isGhost
                        ? DecorationImage(
                            image: NetworkImage(location.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: location.imageUrl == null || isGhost
                      ? Icon(
                          LucideIcons.mapPin,
                          color: Colors.white.withValues(alpha: iconOpacity),
                          size: size * 0.5,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (isGhost) content = Opacity(opacity: 0.85, child: content);

    final pinContent = content;

    if (animateDrop) {
      return pinContent
          .animate()
          .slideY(begin: -2.2, end: 0, duration: 520.ms, curve: Curves.elasticOut)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut);
    }

    return pinContent
        .animate()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 280.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}
