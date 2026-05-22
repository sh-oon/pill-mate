import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// =============================================================================
// Variants & sizes
// =============================================================================

/// 버튼 시각 변형. 시안의 .btp/.btpo/.bts/.btdf/.sln/.erbtn 매핑.
enum AppButtonVariant {
  /// `.btp` — primary 채움. 메인 CTA.
  primary,

  /// `.btpo` — primary tint 채움 + primary 글자. 보조 CTA.
  primaryTint,

  /// `.bts` — 옅은 회색 채움 + textStrong. 다이얼로그 취소 등.
  secondary,

  /// `.btdf` — 빨강 채움 + 흰 글자. 파괴적 액션.
  danger,

  /// `.sln`/`.erbtn` — 흰 배경 + 컬러 보더. 보조 액션.
  outline,

  /// 배경 없는 텍스트 버튼 (배너의 "허용하기" 등).
  ghost,
}

enum AppButtonSize {
  /// 36px 높이.
  sm,

  /// 44px 높이.
  md,

  /// 52px 높이.
  lg,
}

// =============================================================================
// Style override
// =============================================================================

/// `AppButton`의 어느 시각 속성이든 부분 오버라이드.
///
/// 모든 필드 nullable — 지정한 것만 variant 기본값을 덮어씀.
@immutable
class AppButtonStyle {
  const AppButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.radius,
    this.padding,
    this.minHeight,
    this.fontSize,
    this.fontWeight,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;
  final double? fontSize;
  final FontWeight? fontWeight;
}

// =============================================================================
// AppButton
// =============================================================================

/// 디자인 시스템 단일 버튼.
///
/// - [variant]로 색·보더 톤 선택.
/// - [size]로 높이/패딩/라운드 정도 선택.
/// - [icon]/[trailingIcon]/[fullWidth]/[loading]로 컨텐츠 컨트롤.
/// - [style]로 어떤 속성이든 case-by-case 오버라이드.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.fullWidth = false,
    this.loading = false,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;
  final AppButtonStyle? style;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final spec = _ResolvedSpec.of(variant, size, style);

    final content = loading
        ? SizedBox(
            width: spec.fontSize + 4,
            height: spec.fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: spec.foregroundColor,
            ),
          )
        : DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: spec.fontSize,
              fontWeight: spec.fontWeight,
              color: spec.foregroundColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: spec.fontSize + 2, color: spec.foregroundColor),
                  const SizedBox(width: 6),
                ],
                Text(label),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon,
                      size: spec.fontSize + 2, color: spec.foregroundColor),
                ],
              ],
            ),
          );

    final radius = BorderRadius.circular(spec.radius);

    final button = Opacity(
      opacity: _enabled ? 1.0 : 0.4,
      child: Material(
        color: spec.backgroundColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: radius,
          child: Container(
            constraints: BoxConstraints(minHeight: spec.minHeight),
            padding: spec.padding,
            decoration: spec.borderColor == null
                ? null
                : BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: spec.borderColor!,
                      width: spec.borderWidth,
                    ),
                  ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// =============================================================================
// Spec resolution
// =============================================================================

@immutable
class _ResolvedSpec {
  const _ResolvedSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.minHeight,
    required this.fontSize,
    required this.fontWeight,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final double fontSize;
  final FontWeight fontWeight;

  factory _ResolvedSpec.of(
    AppButtonVariant variant,
    AppButtonSize size,
    AppButtonStyle? override,
  ) {
    final (bg, fg, border) = _palette(variant);
    final geom = _sizeGeom(size);

    return _ResolvedSpec(
      backgroundColor: override?.backgroundColor ?? bg,
      foregroundColor: override?.foregroundColor ?? fg,
      borderColor: override?.borderColor ?? border,
      borderWidth: override?.borderWidth ?? 1.0,
      radius: override?.radius ?? geom.radius,
      padding: override?.padding ?? geom.padding,
      minHeight: override?.minHeight ?? geom.minHeight,
      fontSize: override?.fontSize ?? geom.fontSize,
      fontWeight: override?.fontWeight ?? FontWeight.w700,
    );
  }

  static (Color, Color, Color?) _palette(AppButtonVariant v) => switch (v) {
        AppButtonVariant.primary => (AppColors.primary, Colors.white, null),
        AppButtonVariant.primaryTint => (
            AppColors.primaryTint,
            AppColors.primary,
            null
          ),
        AppButtonVariant.secondary => (
            AppColors.border,
            AppColors.textStrong,
            null
          ),
        AppButtonVariant.danger => (AppColors.missed, Colors.white, null),
        AppButtonVariant.outline => (
            AppColors.surface,
            AppColors.textMuted,
            AppColors.border,
          ),
        AppButtonVariant.ghost => (
            Colors.transparent,
            AppColors.primary,
            null
          ),
      };

  static _SizeGeom _sizeGeom(AppButtonSize s) => switch (s) {
        AppButtonSize.sm => const _SizeGeom(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            minHeight: 32,
            fontSize: 12,
            radius: 12,
          ),
        AppButtonSize.md => const _SizeGeom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            minHeight: 44,
            fontSize: 14,
            radius: 14,
          ),
        AppButtonSize.lg => const _SizeGeom(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            minHeight: 52,
            fontSize: 15,
            radius: 16,
          ),
      };
}

@immutable
class _SizeGeom {
  const _SizeGeom({
    required this.padding,
    required this.minHeight,
    required this.fontSize,
    required this.radius,
  });

  final EdgeInsetsGeometry padding;
  final double minHeight;
  final double fontSize;
  final double radius;
}

// =============================================================================
// AppFab — 구조가 다른 floating action button
// =============================================================================

/// 시안 `.fab` — primary 원형 + 흰 아이콘. Scaffold.floatingActionButton 용.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
  });

  final VoidCallback onPressed;
  final IconData icon;

  /// Hero 태그. 같은 Navigator subtree에 여러 FAB이 있을 때 충돌 방지용.
  /// null이면 Hero 애니메이션 비활성화.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      heroTag: heroTag,
      child: Icon(icon, size: 30),
    );
  }
}
