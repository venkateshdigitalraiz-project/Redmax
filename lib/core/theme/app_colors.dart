import 'package:flutter/material.dart';

/// Central theme colors and styling tokens matching the exact dashboard UI.
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF0077F6);
  static const Color primaryDark = Color(0xFF0058C6);
  static const Color primaryLight = Color(0xFF389BFD);
  static const Color primaryNavy = Color(0xFF0F172A);

  // Dashboard Specific Palette
  static const Color dashboardBlue = Color(0xFF0077F6);
  static const Color dashboardDarkNavy = Color(0xFF0A192F);
  static const Color dashboardTextDark = Color(0xFF0F172A);
  static const Color dashboardTextMuted = Color(0xFF64748B);
  static const Color dashboardTextSubtle = Color(0xFF94A3B8);
  static const Color dashboardBg = Color(0xFFF8FAFC);

  // Brand Accents & Alerts
  static const Color accentCoral = Color(0xFFFF5B4F);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);

  // Light Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF9FBFC);
  static const Color card = Color(0xFFFFFFFF);

  // Dark Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0B1320);
  static const Color darkSurface = Color(0xFF161F2E);
  static const Color darkCard = Color(0xFF1A2639);
  static const Color darkBorderLight = Color(0xFF26354D);

  // Alert Surfaces
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color infoSurface = Color(0xFFDBEAFE);
  static const Color errorSurface = Color(0xFFFEE2E2);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Typography Tokens
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Input & Chips
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color chipBackground = Color(0xFFDBEAFE);

  // Service Card Colors (from UI screenshot)
  static const Color carpoolBg = Color(0xFFF0F6FE);
  static const Color carpoolBorder = Color(0xFFD6E6FD);
  static const Color carpoolIcon = Color(0xFF1570EF);
  static const Color carpoolPill = Color(0xFFDBEAFE);

  static const Color deliveryBg = Color(0xFFFFF7ED);
  static const Color deliveryBorder = Color(0xFFFED7AA);
  static const Color deliveryIcon = Color(0xFFEA580C);
  static const Color deliveryPill = Color(0xFFFFEDD5);

  static const Color partyBg = Color(0xFFFAF5FF);
  static const Color partyBorder = Color(0xFFE9D5FF);
  static const Color partyIcon = Color(0xFF9333EA);
  static const Color partyPill = Color(0xFFF3E8FF);

  static const Color toursBg = Color(0xFFF0FDF4);
  static const Color toursBorder = Color(0xFFBBF7D0);
  static const Color toursIcon = Color(0xFF16A34A);
  static const Color toursPill = Color(0xFFDCFCE7);

  static const Color rentalsBg = Color(0xFFF0FDFA);
  static const Color rentalsBorder = Color(0xFF99F6E4);
  static const Color rentalsIcon = Color(0xFF0D9488);
  static const Color rentalsPill = Color(0xFFCCFBF1);

  static const Color fleetBg = Color(0xFFFDF2F8);
  static const Color fleetBorder = Color(0xFFFBCFE8);
  static const Color fleetIcon = Color(0xFFDB2777);
  static const Color fleetPill = Color(0xFFFCE7F3);

  // Admin Theme Accents
  static const Color adminDark = Color(0xFF0B192C);
  static const Color adminCardDark = Color(0xFF1E2E44);
  static const Color adminGold = Color(0xFFFFB800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066EB), Color(0xFF0077F6), Color(0xFF2E90FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerWaveGradient = LinearGradient(
    colors: [Color(0xFF0066EB), Color(0xFF0077F6), Color(0xFF2E90FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient activeRideGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF0A192F), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0077F6), Color(0xFF0A192F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF0B192C), Color(0xFF1E2E44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
