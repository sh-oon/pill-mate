import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum DayMark { none, completed, scheduled, missed }

class DayCellSpec {
  const DayCellSpec({
    required this.day,
    required this.mark,
    this.muted = false,
    this.weekend = WeekendKind.none,
  });

  final int day;
  final DayMark mark;
  final bool muted; // 이전/다음 달 회색
  final WeekendKind weekend;
}

enum WeekendKind { none, sunday, saturday }

/// 달력 한 달 표시 — 7×N 그리드. 선택된 날짜는 primary 원형 배경.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.title,
    required this.cells,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final String title;
  final List<DayCellSpec> cells;
  final int selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;

  static const _dows = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textStrong, size: 22),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textStrong, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _dows[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: i == 0
                            ? AppColors.missed
                            : i == 6
                                ? AppColors.primary
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 14,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: cells.length,
            itemBuilder: (context, i) {
              final c = cells[i];
              return _DayCell(
                spec: c,
                selected: !c.muted && c.day == selectedDay,
                onTap: c.muted ? null : () => onSelect(c.day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final DayCellSpec spec;
  final bool selected;
  final VoidCallback? onTap;

  Color get _textColor {
    if (selected) return Colors.white;
    if (spec.muted) return AppColors.borderHairline;
    return switch (spec.weekend) {
      WeekendKind.sunday => AppColors.missed,
      WeekendKind.saturday => AppColors.primary,
      WeekendKind.none => AppColors.textStrong,
    };
  }

  Color? get _dotColor {
    if (spec.mark == DayMark.none) return null;
    if (selected) return Colors.white;
    return switch (spec.mark) {
      DayMark.completed => AppColors.calendarCompleted,
      DayMark.scheduled => AppColors.primary,
      DayMark.missed => AppColors.missed,
      DayMark.none => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : null,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${spec.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                if (_dotColor != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 18,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _dotColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
