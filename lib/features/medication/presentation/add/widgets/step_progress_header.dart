import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// `.amh` — 닫기/이전 아이콘 + 3-segment 진행바 + "1/3" 카운터.
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    super.key,
    required this.step,
    required this.total,
    required this.onLeading,
  });

  /// 1-based 현재 단계.
  final int step;
  final int total;
  final VoidCallback onLeading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 22,
              color: AppColors.textStrong,
              onPressed: onLeading,
              icon: Icon(step > 1 ? Icons.chevron_left : Icons.close),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? AppColors.primary
                            : AppColors.borderHairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 26,
            child: Text(
              '$step/$total',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
