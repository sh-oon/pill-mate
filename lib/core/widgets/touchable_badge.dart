import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 터치 가능한 라벨/배지.
///
/// CTA 버튼이 아니라 "tappable label" 의도일 때 사용.
/// 예) 섹션 헤더의 "전체보기 ›", 정렬 칩 "이름순 ▾".
///
/// 시각 사양: 흰 배경, 1px hairline 보더, 라운드 14, 28h, 12px font 500.
class TouchableBadge extends StatelessWidget {
  const TouchableBadge({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailingIcon,
    this.color = AppColors.textMuted,
    this.borderColor = AppColors.border,
    this.backgroundColor = AppColors.surface,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color color;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: backgroundColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 2),
                Icon(trailingIcon, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
