import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/sheets/bundle_notification_sheet.dart';
import '../../medication/data/calendar_providers.dart';
import '../../medication/data/reports_providers.dart';
import 'widgets/metric_card_list.dart';
import 'widgets/period_tabs.dart';
import 'widgets/stat_card_2x2.dart';
import 'widgets/week_summary_card.dart';
import 'widgets/weekly_bar_chart.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.weekly;

  /// 막대 차트 상세보기 — 캘린더 탭으로 이동하면서 가장 관련된 날짜를 선택.
  /// 우선순위: 현재(오늘/이번 주/이번 달) → 가장 최근 위험(<60%) → 첫 항목.
  void _openCalendarForBars(List<PeriodBucket> list) {
    if (list.isEmpty) {
      context.go(AppRoute.calendar);
      return;
    }
    final current = list.firstWhere(
      (p) => p.isCurrent,
      orElse: () => list.first,
    );
    final risk = list.lastWhere(
      (p) => p.percent < 60,
      orElse: () => current,
    );
    final target = current.isCurrent ? current : risk;
    ref.read(calendarJumpDateProvider.notifier).set(target.date);
    context.go(AppRoute.calendar);
  }

  @override
  Widget build(BuildContext context) {
    final period = _period;
    final summaryAsync = ref.watch(periodSummaryProvider(period));
    final bucketsAsync = ref.watch(periodBucketsProvider(period));
    final streakAsync = ref.watch(streakProvider);
    final bestTimeAsync = ref.watch(periodBestTimeOfDayProvider(period));
    final totalAsync = ref.watch(periodTotalCompletedProvider(period));
    final deltaAsync = ref.watch(periodDeltaPercentProvider(period));

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
              onSettingsTap: () => context.push(AppRoute.settings),
            ),
            PeriodTabs(
              value: _period,
              onChange: (v) => setState(() => _period = v),
            ),
            summaryAsync.when(
              loading: () => const _LoadingCard(height: 280),
              error: (e, _) => _ErrorCard(error: e),
              data: (s) => WeekSummaryCard(
                label: periodTitleLabel(period),
                dateRange: periodRangeLabel(s.range),
                progress: s.progress,
                done: s.done,
                total: s.total,
                deltaPercent: deltaAsync.value,
              ),
            ),
            summaryAsync.when(
              loading: () => const _LoadingCard(height: 160),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => StatCard2x2(
                cards: [
                  StatCardSpec(
                    icon: Icons.check_rounded,
                    label: '완료',
                    count: s.done,
                    tone: StatTone.completed,
                  ),
                  StatCardSpec(
                    icon: Icons.access_time_rounded,
                    label: '예정',
                    count: s.pending,
                    tone: StatTone.scheduled,
                  ),
                  StatCardSpec(
                    icon: Icons.error_outline_rounded,
                    label: '놓침',
                    count: s.missed,
                    tone: StatTone.missed,
                  ),
                  StatCardSpec(
                    icon: Icons.format_list_bulleted_rounded,
                    label: '전체',
                    count: s.total,
                    tone: StatTone.total,
                  ),
                ],
              ),
            ),
            MetricCardList(
              rows: [
                MetricRowSpec(
                  icon: Icons.water_drop_outlined,
                  label: '연속 복용',
                  sublabel: '오늘까지 모두 챙긴 일수',
                  value: streakAsync.when(
                    loading: () => '…',
                    error: (_, _) => '-',
                    data: (n) => '$n일',
                  ),
                  tone: MetricTone.blue,
                ),
                MetricRowSpec(
                  icon: Icons.access_time_rounded,
                  label: '가장 잘 챙긴 시간대',
                  sublabel: bestTimeAsync.when(
                    loading: () => '계산 중',
                    error: (_, _) => '-',
                    data: (b) => b == null
                        ? '데이터 부족'
                        : '완료율 ${(b.completionRate * 100).round()}%',
                  ),
                  value: bestTimeAsync.when(
                    loading: () => '…',
                    error: (_, _) => '-',
                    data: (b) => b?.timeOfDay ?? '-',
                  ),
                  tone: MetricTone.purple,
                ),
                MetricRowSpec(
                  icon: Icons.event_available_rounded,
                  label: '총 완료 횟수',
                  sublabel: _totalSublabel(period),
                  value: totalAsync.when(
                    loading: () => '…',
                    error: (_, _) => '-',
                    data: (n) => '$n회',
                  ),
                  tone: MetricTone.green,
                ),
              ],
            ),
            bucketsAsync.when(
              loading: () => const _LoadingCard(height: 220),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) => WeeklyBarChart(
                title: periodChartTitle(period),
                bars: [
                  for (final p in list)
                    WeeklyBar(
                      day: p.label,
                      percent: p.percent,
                      isToday: p.isCurrent,
                      isRisk: p.percent < 60,
                    ),
                ],
                onDetailTap: () => _openCalendarForBars(list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _totalSublabel(ReportPeriod period) => switch (period) {
      ReportPeriod.weekly => '이번 주 합계',
      ReportPeriod.monthly => '이번 달 합계',
      ReportPeriod.yearly => '올해 합계',
    };

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Text(
        '불러오기 실패: $error',
        style: const TextStyle(fontSize: 13, color: AppColors.missed),
      ),
    );
  }
}
