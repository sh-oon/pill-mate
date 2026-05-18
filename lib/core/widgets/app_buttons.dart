import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.btp` — 기본 채워진 primary 버튼. 사이즈 변형 sm/md/lg.
enum AppButtonSize { sm, md, lg }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool fullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spec = switch (size) {
      AppButtonSize.sm => (
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          minHeight: 36.0,
          fontSize: 14.0,
          radius: 12.0,
        ),
      AppButtonSize.md => (
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minHeight: 44.0,
          fontSize: 14.0,
          radius: 14.0,
        ),
      AppButtonSize.lg => (
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          minHeight: 52.0,
          fontSize: 15.0,
          radius: 16.0,
        ),
    };

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        padding: spec.padding,
        minimumSize: Size(0, spec.minHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spec.radius),
        ),
        textStyle:
            TextStyle(fontSize: spec.fontSize, fontWeight: FontWeight.w700),
      ),
      child: icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: spec.fontSize + 2),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 흰 배경 + 컬러 보더 outline 버튼 — "전체보기", "기록 수정" 등.
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.textMuted,
    this.borderColor,
    this.icon,
    this.trailingIcon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// 글자/아이콘 색. 기본은 muted, missed 등으로 오버라이드.
  final Color color;

  /// 보더 색. null이면 [color]와 동일.
  final Color? borderColor;

  final IconData? icon;
  final IconData? trailingIcon;

  /// 작은 버전 (예: "전체보기").
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 10.0;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: color,
        side: BorderSide(color: borderColor ?? color, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 12,
          vertical: compact ? 6 : 7,
        ),
        minimumSize: Size(0, compact ? 28 : 32),
        textStyle: TextStyle(
          fontSize: compact ? 12 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(trailingIcon, size: 14),
          ],
        ],
      ),
    );
  }
}

/// `.btdf` — 빨강 destructive 버튼 (filled).
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.missed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
