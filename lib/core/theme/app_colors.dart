import 'package:flutter/material.dart';

class AppColors {
  // Base backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Soft Blue primary palette
  static const Color primary = Color(0xFF0284C7); // Soft modern blue
  static const Color primaryLight = Color(0xFFE0F2FE); // Very light blue container
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color accent = Color(0xFF38BDF8);

  // Neutral slate text & borders
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Feedback states
  static const Color correctGreen = Color(0xFF10B981);
  static const Color correctLight = Color(0xFFECFDF5);
  static const Color wrongRed = Color(0xFFEF4444);
  static const Color wrongLight = Color(0xFFFEF2F2);

  // Premium & Warning
  static const Color premiumGold = Color(0xFFD97706);
  static const Color premiumLight = Color(0xFFFFFBEB);

  // Card & Container Shadows
  static List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
