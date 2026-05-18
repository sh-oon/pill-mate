import 'package:flutter/material.dart';

/// 디자인 토큰 색상 팔레트.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF4661F2);
  static const Color primaryTint = Color(0xFFE8ECFB);

  // Surface
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFECEEF2);

  // Text
  static const Color textStrong = Color(0xFF1A1B2E);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFFA0A4AE);

  // Border
  static const Color border = Color(0xFFF0F1F4);
  static const Color borderHairline = Color(0xFFE5E7EB);

  // Status
  static const Color success = Color(0xFF1FB068);
  static const Color successTint = Color(0xFFDEF7E5);
  static const Color scheduled = primary;
  static const Color scheduledTint = primaryTint;
  static const Color missed = Color(0xFFFF5252);
  static const Color missedTint = Color(0xFFFFE2E2);
  static const Color missedBorder = Color(0xFFFFB8B8);

  // Accent (cheeks etc.)
  static const Color accentPink = Color(0xFFFF85A1);
}
