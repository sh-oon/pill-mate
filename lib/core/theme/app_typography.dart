import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Pretendard 기반 타이포 토큰.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Pretendard';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.5,
    color: AppColors.textStrong,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.textStrong,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: AppColors.textMuted,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textStrong,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Material TextTheme 생성 (기본 색상은 onSurface로 두고 위젯에서 토큰 직접 사용 권장).
  static TextTheme textTheme(ColorScheme scheme) {
    Color strong = scheme.onSurface;
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: strong),
      headlineSmall: displayLarge.copyWith(fontSize: 22, color: strong),
      titleLarge: titleLarge.copyWith(color: strong),
      titleMedium: titleMedium.copyWith(color: strong),
      titleSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ).copyWith(color: strong),
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium.copyWith(color: strong),
      bodySmall: bodySmall,
      labelLarge: button,
      labelMedium: labelStrong.copyWith(color: strong),
      labelSmall: bodySmall,
    );
  }
}
