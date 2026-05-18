import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum ReportPeriod { weekly, monthly, yearly }

/// `.rtabs` — 흰 라운드 컨테이너 안 세그먼트 컨트롤.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({
    super.key,
    required this.value,
    required this.onChange,
  });

  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChange;

  static const _items = <(ReportPeriod, String)>[
    (ReportPeriod.weekly, '주간'),
    (ReportPeriod.monthly, '월간'),
    (ReportPeriod.yearly, '연간'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final it in _items)
            Expanded(child: _TabCell(item: it, value: value, onChange: onChange)),
        ],
      ),
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.item,
    required this.value,
    required this.onChange,
  });

  final (ReportPeriod, String) item;
  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChange;

  @override
  Widget build(BuildContext context) {
    final selected = item.$1 == value;
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => onChange(item.$1),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              item.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
