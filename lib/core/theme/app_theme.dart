import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ).copyWith(
      surface: AppColors.surface,
      onSurface: AppColors.textStrong,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      outlineVariant: AppColors.border,
    );
    return _base(scheme, brightness: Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    return _base(scheme, brightness: Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, {required Brightness brightness}) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor:
          isLight ? AppColors.background : scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: AppTypography.textTheme(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.background : scheme.surface,
        foregroundColor:
            isLight ? AppColors.textStrong : scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isLight ? AppColors.textStrong : scheme.onSurface,
          fontSize: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textStrong,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
