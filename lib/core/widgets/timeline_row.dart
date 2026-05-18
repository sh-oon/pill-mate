import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "시간 + dot | 카드" 가로 배치 — 홈/캘린더 일정 타임라인 공통.
///
/// 시각 텍스트는 [time], dot 색은 [dotColor]로 슬롯별 상태 표현.
/// 우측 카드 본문은 [child].
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.time,
    required this.child,
    this.dotColor = AppColors.primary,
    this.timeColor = AppColors.primary,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 14),
  });

  final String time;
  final Widget child;
  final Color dotColor;
  final Color timeColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: timeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
