import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'icon_circle_badge.dart';

/// 4-칸 통계 셀의 하나.
class StatCell {
  const StatCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.filled = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  /// true면 원형 컬러 배경 안에 흰 아이콘 (홈 "완료" 셀처럼).
  final bool filled;
  final VoidCallback? onTap;
}

/// 4-column 통계 그리드 — 홈 요약카드, 리포트 등에서 공통 사용.
class StatGrid4 extends StatelessWidget {
  const StatGrid4({super.key, required this.cells});

  final List<StatCell> cells;

  @override
  Widget build(BuildContext context) {
    assert(cells.length == 4, 'StatGrid4는 정확히 4개 셀 필요');
    return Row(
      children: [
        for (final c in cells)
          Expanded(child: _Cell(cell: c)),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell});
  final StatCell cell;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          IconCircleBadge(
            icon: cell.icon,
            iconColor: cell.filled ? Colors.white : cell.iconColor,
            backgroundColor: cell.filled ? cell.iconColor : null,
            filled: cell.filled,
          ),
          const SizedBox(height: 6),
          Text(
            cell.label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          // count 변경 시 implicit IntTween — 마크 액션 직후 숫자가 자연스럽게
          // 올라가는 micro-interaction. 첫 빌드에선 0→실제값 진입 효과도 함께.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: cell.count),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value개',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    if (cell.onTap == null) return body;
    return InkWell(
      onTap: cell.onTap,
      borderRadius: BorderRadius.circular(12),
      child: body,
    );
  }
}
