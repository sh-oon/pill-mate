import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 필터/카테고리 선택 칩 — "전체/완료/예정/놓침" 또는 "전체/영양제/약".
///
/// [icon]과 [count] 모두 선택. 캘린더처럼 `<icon> 완료 5` 패턴 또는
/// 약 서랍처럼 `전체` 단일 텍스트 모두 지원.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textMuted;
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                count == null ? label : '$label $count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
