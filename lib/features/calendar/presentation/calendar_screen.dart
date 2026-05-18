import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/intake_logs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/sheets/bundle_notification_sheet.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/timeline_row.dart';
import '../../medication/data/calendar_providers.dart';
import '../../medication/data/intake_repository.dart';
import 'widgets/calendar_legend.dart';
import 'widgets/month_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;
  _DayFilter _filter = _DayFilter.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewYear = now.year;
    _viewMonth = now.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      var y = _viewYear, m = _viewMonth + delta;
      while (m < 1) {
        m += 12;
        y -= 1;
      }
      while (m > 12) {
        m -= 12;
        y += 1;
      }
      _viewYear = y;
      _viewMonth = m;
    });
  }

  List<DayCellSpec> _buildCells(Map<int, DayMarkKind> marks) {
    final cells = <DayCellSpec>[];
    final first = DateTime(_viewYear, _viewMonth, 1);
    // weekday of first day (Mon=1..Sun=7), 일요일 시작 칸 정렬
    final firstDow = first.weekday % 7; // Mon=1..Sat=6, Sun=0
    // 이전 달 회색 채우기
    final prevMonthEnd = DateTime(_viewYear, _viewMonth, 0);
    for (var i = firstDow; i > 0; i--) {
      final d = prevMonthEnd.day - i + 1;
      cells.add(DayCellSpec(day: d, mark: DayMark.none, muted: true));
    }
    final daysInMonth =
        DateTime(_viewYear, _viewMonth + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final dw = DateTime(_viewYear, _viewMonth, d).weekday;
      final weekend = dw == DateTime.sunday
          ? WeekendKind.sunday
          : dw == DateTime.saturday
              ? WeekendKind.saturday
              : WeekendKind.none;
      cells.add(DayCellSpec(
        day: d,
        mark: _toCellMark(marks[d] ?? DayMarkKind.none),
        weekend: weekend,
      ));
    }
    return cells;
  }

  DayMark _toCellMark(DayMarkKind k) => switch (k) {
        DayMarkKind.completed => DayMark.completed,
        DayMarkKind.scheduled => DayMark.scheduled,
        DayMarkKind.missed => DayMark.missed,
        DayMarkKind.none => DayMark.none,
      };

  String _recordsTitleFor(DateTime date) {
    const dow = ['월', '화', '수', '목', '금', '토', '일'];
    final w = dow[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($w) 복용 기록';
  }

  @override
  Widget build(BuildContext context) {
    final marksAsync = ref.watch(
      monthMarksProvider((year: _viewYear, month: _viewMonth)),
    );
    final dosesAsync = ref.watch(dayDosesProvider(_selectedDate));
    final records = dosesAsync.value ?? const <DoseInstance>[];
    final counts = {
      IntakeStatus.taken:
          records.where((r) => r.status == IntakeStatus.taken).length,
      IntakeStatus.pending:
          records.where((r) => r.status == IntakeStatus.pending).length,
      IntakeStatus.missed:
          records.where((r) => r.status == IntakeStatus.missed).length,
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
                time: '',
                meds: const [],
              ),
            ),
            MonthGrid(
              title: '$_viewYear년 $_viewMonth월',
              cells: _buildCells(marksAsync.value ?? const {}),
              selectedDay:
                  (_selectedDate.year == _viewYear &&
                          _selectedDate.month == _viewMonth)
                      ? _selectedDate.day
                      : -1,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onSelect: (d) => setState(() {
                _selectedDate = DateTime(_viewYear, _viewMonth, d);
              }),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: CalendarLegend(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Text(
                _recordsTitleFor(_selectedDate),
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
            if (dosesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4)),
              )
            else if (filtered.isEmpty)
              const _EmptyRecord()
            else
              for (final r in filtered)
                TimelineRow(
                  time: r.timeOfDay,
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

Color _statusColor(IntakeStatus s) => switch (s) {
      IntakeStatus.taken => AppColors.calendarCompleted,
      IntakeStatus.pending => AppColors.primary,
      IntakeStatus.missed => AppColors.missed,
      IntakeStatus.skipped => AppColors.textMuted,
    };

DoseStatus _toBadgeStatus(IntakeStatus s) => switch (s) {
      IntakeStatus.taken => DoseStatus.done,
      IntakeStatus.pending => DoseStatus.scheduled,
      IntakeStatus.missed => DoseStatus.missed,
      IntakeStatus.skipped => DoseStatus.done,
    };

// ============================================================
// 필터 행
// ============================================================

enum _DayFilter { all, completed, scheduled, missed }

extension on _DayFilter {
  IntakeStatus toStatus() => switch (this) {
        _DayFilter.completed => IntakeStatus.taken,
        _DayFilter.scheduled => IntakeStatus.pending,
        _DayFilter.missed => IntakeStatus.missed,
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
  final Map<IntakeStatus, int> counts;
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
              count: counts[IntakeStatus.taken] ?? 0,
              selected: filter == _DayFilter.completed,
              onTap: () => onChange(_DayFilter.completed),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilterPill(
              label: '예정',
              icon: Icons.access_time_rounded,
              count: counts[IntakeStatus.pending] ?? 0,
              selected: filter == _DayFilter.scheduled,
              onTap: () => onChange(_DayFilter.scheduled),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilterPill(
              label: '놓침',
              icon: Icons.error_outline_rounded,
              count: counts[IntakeStatus.missed] ?? 0,
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
  final DoseInstance record;

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
          PillIcon.svg(medName: record.medicationName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.medicationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CategoryChip.fromCode(record.category ?? 'sup'),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.quantityLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: _toBadgeStatus(record.status)),
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
