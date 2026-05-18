import 'package:flutter/material.dart';

/// 디자인 토큰 색상 팔레트.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF4661F2);
  static const Color primaryTint = Color(0xFFE8ECFB);
  static const Color primarySurface = Color(0xFFF6F8FF); // 강조 카드(다음 복용) bg
  static const Color lavenderRing = Color(0xFFD8DEF8); // 도넛 배경 링

  // Surface
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFECEEF2);
  static const Color missedSoft = Color(0xFFFFF7F7); // 놓친 복용 배너 soft bg

  // Pill swatches (홈 일정 카드 더미 데이터)
  static const Color pillPink = Color(0xFFFF85A1);
  static const Color pillYellow = Color(0xFFFFD568);
  static const Color pillBlue = Color(0xFF4D88FF);
  static const Color pillBlueLight = Color(0xFF92B6FF);
  static const Color pillOrange = Color(0xFFFFB52E);
  static const Color pillPurple = Color(0xFFB19DFB);

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
  static const Color accentPurple = Color(0xFF9B7CFF); // 리포트 메트릭(시간대)
  static const Color accentPurpleTint = Color(0xFFF0EBFE);

  // Calendar
  static const Color calendarCompleted = Color(0xFF2DCB7B); // success보다 밝은 녹색
}
