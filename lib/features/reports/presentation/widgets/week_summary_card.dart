import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/donut_progress.dart';

/// `.rh2` — 라벤더 배경 큰 도넛 + 통계 메시지.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({
    super.key,
    required this.label,
    required this.dateRange,
    required this.progress,
    required this.done,
    required this.total,
    required this.deltaPercent,
  });

  final String label; // "이번 주 리포트"
  final String dateRange; // "5월 10일 - 5월 16일"
  final double progress; // 0~1
  final int done;
  final int total;
  final int deltaPercent; // +5, -3 등

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateRange,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          DonutProgress(progress: progress, size: 170, strokeWidth: 12),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textStrong,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
              children: [
                TextSpan(text: '$total회 중 '),
                TextSpan(
                  text: '$done회 완료',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '했어요\n'),
                TextSpan(
                  text:
                      '지난 주보다 ${deltaPercent >= 0 ? '+' : ''}$deltaPercent% ${deltaPercent >= 0 ? '상승' : '하락'}했어요',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
