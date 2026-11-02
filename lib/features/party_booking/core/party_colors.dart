import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';

/// Party Booking colour tokens.
///
/// Neutrals, status and text colours are re-used from the app-wide [AppColors]
/// so the module follows the global theme. Only the module's purple brand
/// palette (taken from the Party Booking design) is defined here.
class PartyColors {
  PartyColors._();

  // Module brand (purple)
  static const Color primary = Color(0xFF4A21C4);
  static const Color primaryDark = Color(0xFF361A9E);
  static const Color primaryLight = Color(0xFF6B45E6);
  static const Color headerFill = Color(0xFF4C15D6);
  static const Color heroStart = Color(0xFF1B0A55);
  static const Color heroEnd = Color(0xFF5B24D6);
  static const Color glowPink = Color(0xFFE040FB);
  static const Color tile = Color(0xFFF3F1FB);
  static const Color chip = Color(0xFFF1EFFA);

  // Shared tokens from AppColors
  static const Color text = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color subtle = AppColors.textTertiary;
  static const Color border = AppColors.border;
  static const Color surface = AppColors.surface;
  static const Color star = AppColors.star;
  static const Color error = AppColors.error;
  static const Color success = AppColors.success;
  static const Color successSurface = AppColors.successSurface;
  static const Color info = AppColors.info;
  static const Color infoSurface = AppColors.infoSurface;
  static const Color errorSurface = AppColors.errorSurface;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroStart, Color(0xFF3A15A8), heroEnd],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF571DE6),
      Color(0xFF4210B7),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}
