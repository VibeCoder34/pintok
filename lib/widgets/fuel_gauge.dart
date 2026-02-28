import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Reusable fuel gauge: progress bar and "X / Y Scans used" with brand color #f05130.
class FuelGauge extends StatelessWidget {
  const FuelGauge({
    super.key,
    required this.scansUsed,
    this.scansLimit,
    this.loading = false,
    this.compact = false,
  });

  final int scansUsed;
  final int? scansLimit;
  final bool loading;
  /// When true, shows a single-line compact layout (e.g. for profile header).
  final bool compact;

  static const Color _fuelColor = Color(0xFFF05130); // Brand #f05130

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = scansLimit != null && scansLimit! > 0;
    final progress = hasLimit
        ? (scansUsed.clamp(0, scansLimit!) / scansLimit!).clamp(0.0, 1.0)
        : 0.0;

    if (loading) {
      return SizedBox(
        height: compact ? 24 : 32,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _fuelColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      );
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasLimit ? progress : null,
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation<Color>(_fuelColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasLimit ? '$scansUsed / $scansLimit' : '$scansUsed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: hasLimit ? progress : null,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation<Color>(_fuelColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasLimit
              ? '$scansUsed / $scansLimit Scans used'
              : '$scansUsed Scans used',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
