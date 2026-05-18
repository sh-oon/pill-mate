import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 복용 상태 — 완료 / 예정 / 놓침.
enum DoseStatus { done, scheduled, missed }

/// 상태별 컬러 페어.
class _StatusStyle {
  const _StatusStyle(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;
}

const _styles = {
  DoseStatus.done:
      _StatusStyle('완료', AppColors.successTint, AppColors.success),
  DoseStatus.scheduled:
      _StatusStyle('예정', AppColors.primaryTint, AppColors.primary),
  DoseStatus.missed:
      _StatusStyle('놓침', AppColors.missedTint, AppColors.missed),
};

/// 작은 상태 배지 — 완료/예정/놓침 컬러 칩.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DoseStatus status;

  @override
  Widget build(BuildContext context) {
    final s = _styles[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: s.fg,
        ),
      ),
    );
  }
}
