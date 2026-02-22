import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/mock_location.dart';
import '../theme/app_theme.dart';

/// Custom map pin: small circular "profile" of the location with neon border.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.location,
    this.size = 44,
    this.isSelected = false,
    this.onTap,
  });

  final MockLocation location;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = location.thumbnailColor ?? AppColors.primaryAccent;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 12,
        height: size + 12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.primaryAccent : color).withValues(alpha: 0.4),
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
                  color: isSelected ? AppColors.primaryAccent : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
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
                    color: color,
                    image: location.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(location.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: location.imageUrl == null
                      ? Icon(
                          LucideIcons.mapPin,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: size * 0.5,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 280.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}
