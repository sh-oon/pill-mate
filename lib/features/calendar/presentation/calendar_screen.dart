import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/sheets/bundle_notification_sheet.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/timeline_row.dart';
import 'widgets/calendar_legend.dart';
import 'widgets/month_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // --- 시안 fixture ---
  static const _completedDays = {
    1, 2, 4, 5, 7, 8, 9, 11, 12, 13, 15, 19, 20, 21, 22, 23,
    26, 27, 28, 29, 30,
  };
  static const _missedDays = {6, 16};
  static const _scheduledDays = {14};
  static const _mutedPrevMonth = [27, 28, 29, 30]; // 4월 말 회색

  int _selectedDay = 14;
  _DayFilter _filter = _DayFilter.all;

  List<DayCellSpec> _buildCells() {
    final cells = <DayCellSpec>[];
    for (final d in _mutedPrevMonth) {
      cells.add(DayCellSpec(day: d, mark: DayMark.none, muted: true));
    }
    for (var d = 1; d <= 31; d++) {
      final dw = (d + 3) % 7; // 5월 1일이 목요일이라 시안과 동일하게 +3
      final weekend = switch (dw) {
        0 => WeekendKind.sunday,
        6 => WeekendKind.saturday,
        _ => WeekendKind.none,
      };
      final mark = _completedDays.contains(d)
          ? DayMark.completed
          : _scheduledDays.contains(d)
              ? DayMark.scheduled
              : _missedDays.contains(d)
                  ? DayMark.missed
                  : DayMark.none;
      cells.add(DayCellSpec(day: d, mark: mark, weekend: weekend));
    }
    return cells;
  }

  /// 선택 일자의 기록 (mockup의 recBase).
  List<_Record> _recordsForDay(int day) {
    return switch (day) {
      14 => const [
          _Record(time: '08:00', name: '종합비타민', qty: '1정', status: DoseStatus.done),
          _Record(time: '08:00', name: '유산균', qty: '1캡슐', status: DoseStatus.done),
          _Record(time: '12:00', name: '오메가3', qty: '1캡슐', status: DoseStatus.scheduled),
          _Record(time: '21:00', name: '마그네슘', qty: '1정', status: DoseStatus.missed),
        ],
      6 => const [
          _Record(time: '08:00', name: '유산균', qty: '1캡슐', status: DoseStatus.done),
          _Record(time: '21:00', name: '마그네슘', qty: '1정', status: DoseStatus.missed),
        ],
      16 => const [
          _Record(time: '21:00', name: '비타민D', qty: '1정', status: DoseStatus.missed),
        ],
      _ => const [],
    };
  }

  String _recordsTitleFor(int day) {
    const dow = ['목', '금', '토', '일', '월', '화', '수']; // 5/1 = 목 기준
    final w = dow[(day - 1) % 7];
    return '5월 $day일 ($w) 복용 기록';
  }

  @override
  Widget build(BuildContext context) {
    final records = _recordsForDay(_selectedDay);
    final counts = {
      DoseStatus.done: records.where((r) => r.status == DoseStatus.done).length,
      DoseStatus.scheduled:
          records.where((r) => r.status == DoseStatus.scheduled).length,
      DoseStatus.missed:
          records.where((r) => r.status == DoseStatus.missed).length,
    };

    final filtered = _filter == _DayFilter.all
        ? records
        : records.where((r) => r.status == _filter.toStatus()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            AppTopBar(
              onBellTap: () => BundleNotificationSheet.show(
                context,
                time: '21:00',
                meds: const [
                  BundleMed(name: '마그네슘', quantity: '1정'),
                  BundleMed(name: '알레르기 약', quantity: '1정'),
                ],
              ),
            ),
            MonthGrid(
              title: '2025년 5월',
              cells: _buildCells(),
              selectedDay: _selectedDay,
              onPrev: () {},
              onNext: () {},
              onSelect: (d) => setState(() => _selectedDay = d),
            ),
            // 카드 안에는 못 들어가게 분리한 범례
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: CalendarLegend(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Text(
                _recordsTitleFor(_selectedDay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            _DayFilterRow(
              filter: _filter,
              onChange: (f) => setState(() => _filter = f),
              counts: counts,
              total: records.length,
            ),
            if (filtered.isEmpty)
              const _EmptyRecord()
            else
              for (final r in filtered)
                TimelineRow(
                  time: r.time,
                  dotColor: _statusColor(r.status),
                  timeColor: _statusColor(r.status),
                  child: _RecordCard(record: r),
                ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(DoseStatus s) => switch (s) {
      DoseStatus.done => AppColors.calendarCompleted,
      DoseStatus.scheduled => AppColors.primary,
      DoseStatus.missed => AppColors.missed,
    };

// ============================================================
// 필터 행
// ============================================================

enum _DayFilter { all, completed, scheduled, missed }

extension on _DayFilter {
  DoseStatus toStatus() => switch (this) {
        _DayFilter.completed => DoseStatus.done,
        _DayFilter.scheduled => DoseStatus.scheduled,
        _DayFilter.missed => DoseStatus.missed,
        _DayFilter.all => throw StateError('all has no single status'),
      };
}

class _DayFilterRow extends StatelessWidget {
  const _DayFilterRow({
    required this.filter,
    required this.onChange,
    required this.counts,
    required this.total,
  });

  final _DayFilter filter;
  final ValueChanged<_DayFilter> onChange;
  final Map<DoseStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Row(
        children: [
          Expanded(
            child: FilterPill(
              label: '전체',
              icon: Icons.format_list_bulleted_rounded,
              count: total,
              selected: filter == _DayFilter.all,
              onTap: () => onChange(_DayFilter.all),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilterPill(
              label: '완료',
              icon: Icons.check_rounded,
              count: counts[DoseStatus.done] ?? 0,
              selected: filter == _DayFilter.completed,
              onTap: () => onChange(_DayFilter.completed),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilterPill(
              label: '예정',
              icon: Icons.access_time_rounded,
              count: counts[DoseStatus.scheduled] ?? 0,
              selected: filter == _DayFilter.scheduled,
              onTap: () => onChange(_DayFilter.scheduled),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilterPill(
              label: '놓침',
              icon: Icons.error_outline_rounded,
              count: counts[DoseStatus.missed] ?? 0,
              selected: filter == _DayFilter.missed,
              onTap: () => onChange(_DayFilter.missed),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 기록 카드 + empty
// ============================================================

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final _Record record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          PillIcon.svg(medName: record.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const CategoryChip(label: '영양제'),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.qty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: record.status),
        ],
      ),
    );
  }
}

class _EmptyRecord extends StatelessWidget {
  const _EmptyRecord();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          '복용 기록이 없어요',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ============================================================
// 데이터
// ============================================================

class _Record {
  const _Record({
    required this.time,
    required this.name,
    required this.qty,
    required this.status,
  });

  final String time;
  final String name;
  final String qty;
  final DoseStatus status;
}
