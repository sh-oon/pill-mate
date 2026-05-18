import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 작은 회색 카테고리 칩 — "영양제" / "약".
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label});

  /// 분류 코드(sup/med) → 한국어 라벨 매핑.
  factory CategoryChip.fromCode(String code) {
    return CategoryChip(label: code == 'med' ? '약' : '영양제');
  }

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
