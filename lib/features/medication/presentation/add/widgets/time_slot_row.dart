import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// `.tsl` 시간 슬롯 한 행 — 시각 + 우측 삭제 X 아이콘.
class TimeSlotRow extends StatelessWidget {
  const TimeSlotRow({
    super.key,
    required this.time,
    required this.onRemove,
  });

  final String time;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

/// `.attb` — dashed outline "+ 시간 추가" 버튼.
class AddTimeDashedButton extends StatelessWidget {
  const AddTimeDashedButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 11),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: const Text('+ 시간 추가'),
      ),
    );
  }
}
