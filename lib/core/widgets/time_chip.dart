import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.tcp` 시간 chip — "08:00" 같은 시각 표시용 작은 pill.
class TimeChip extends StatelessWidget {
  const TimeChip({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
