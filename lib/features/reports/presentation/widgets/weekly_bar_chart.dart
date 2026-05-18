import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WeeklyBar {
  const WeeklyBar({
    required this.day,
    required this.percent,
    this.isToday = false,
    this.isRisk = false,
  });

  final String day; // "금"/"토"/"오늘"
  final int percent; // 0~100
  final bool isToday;

  /// true면 빨간색으로 강조 (낮은 완료율 경고).
  final bool isRisk;
}

/// `.chc` — 흰 박스 안 7일 막대 차트 + 헤더 액션.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.bars,
    required this.onDetailTap,
  });

  final List<WeeklyBar> bars;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 7일 복용 추이',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              InkWell(
                onTap: onDetailTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '자세히 보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in bars)
                    Expanded(child: _Bar(bar: b)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar});
  final WeeklyBar bar;

  @override
  Widget build(BuildContext context) {
    final color = bar.isRisk ? AppColors.missed : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${bar.percent}%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 220),
            heightFactor: bar.percent / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bar.day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: bar.isToday ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
