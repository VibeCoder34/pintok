import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PinTok design tokens — Midnight & Neon, dark-only.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color primaryAccent = Color(0xFF007AFF);
  static const Color secondaryAccent = Color(0xFFFF0050);

  static const Color surfaceDark = Color(0xFF121212);
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
}

/// App-wide theme and glassmorphic decoration styles.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark().textTheme;
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
    } catch (_) {
      textTheme = baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  /// Blur sigma for glass panels.
  static const double glassBlurSigma = 24.0;

  /// Thin border opacity for glass edges.
  static const double glassBorderOpacity = 0.12;

  /// Creates a glassmorphic container decoration with optional gradient border.
  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    List<Color>? borderGradientColors,
    double borderWidth = 1.0,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return BoxDecoration(
      borderRadius: radius,
      color: Colors.white.withValues(alpha: 0.06),
      border: Border.all(
        color: borderGradientColors != null
            ? Colors.transparent
            : Colors.white.withValues(alpha: glassBorderOpacity),
        width: borderWidth,
      ),
    );
  }

  /// Wraps [child] in a clip + backdrop blur for glass effect.
  static Widget glassPanel({
    required Widget child,
    BorderRadius? borderRadius,
    double sigma = glassBlurSigma,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  /// Gradient for the PinTok title (blue → pink).
  static const LinearGradient brandGradient = LinearGradient(
    colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Shimmer / glow gradient for the drop zone border.
  static const LinearGradient neonBorderGradient = LinearGradient(
    colors: [
      AppColors.primaryAccent,
      Color(0xFF00D4FF),
      AppColors.secondaryAccent,
      AppColors.primaryAccent,
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
