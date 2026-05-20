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

/// `.chc` — 흰 박스 안 가변 길이 막대 차트 + 헤더 액션.
///
/// weekly(7일)/monthly(4~5주)/yearly(12개월) 모두 지원 — `bars` 개수에 맞춰
/// Expanded로 자동 분할.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.bars,
    required this.onDetailTap,
    this.title = '최근 7일 복용 추이',
  });

  final List<WeeklyBar> bars;
  final VoidCallback onDetailTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    // 막대 개수가 많아지면 (yearly=12) 바 너비를 줄여 화면에 들어오도록.
    final barWidth = bars.length <= 7 ? 22.0 : (bars.length <= 10 ? 18.0 : 14.0);

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
              Text(
                title,
                style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in bars)
                  Expanded(child: _Bar(bar: b, barWidth: barWidth)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.barWidth});
  final WeeklyBar bar;
  final double barWidth;

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
          width: barWidth,
          height: 90,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 220),
              heightFactor: bar.percent / 100,
              widthFactor: 1.0,
              child: ColoredBox(color: color),
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
