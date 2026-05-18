import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
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

  // --- 시안 fixture ---
  static const _weeklyBars = [
    WeeklyBar(day: '금', percent: 71),
    WeeklyBar(day: '토', percent: 86),
    WeeklyBar(day: '일', percent: 100),
    WeeklyBar(day: '월', percent: 71),
    WeeklyBar(day: '화', percent: 57, isRisk: true),
    WeeklyBar(day: '수', percent: 86),
    WeeklyBar(day: '오늘', percent: 80, isToday: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            AppTopBar(
              onBellTap: () => context.push(AppRoute.settings),
            ),
            PeriodTabs(
              value: _period,
              onChange: (v) => setState(() => _period = v),
            ),
            const WeekSummaryCard(
              label: '이번 주 리포트',
              dateRange: '5월 10일 - 5월 16일',
              progress: 0.8,
              done: 28,
              total: 35,
              deltaPercent: 5,
            ),
            const StatCard2x2(
              cards: [
                StatCardSpec(
                  icon: Icons.check_rounded,
                  label: '완료',
                  count: 28,
                  tone: StatTone.completed,
                ),
                StatCardSpec(
                  icon: Icons.access_time_rounded,
                  label: '예정',
                  count: 5,
                  tone: StatTone.scheduled,
                ),
                StatCardSpec(
                  icon: Icons.error_outline_rounded,
                  label: '놓침',
                  count: 2,
                  tone: StatTone.missed,
                ),
                StatCardSpec(
                  icon: Icons.format_list_bulleted_rounded,
                  label: '전체',
                  count: 35,
                  tone: StatTone.total,
                ),
              ],
            ),
            const MetricCardList(
              rows: [
                MetricRowSpec(
                  icon: Icons.water_drop_outlined,
                  label: '연속 복용',
                  sublabel: '최고 12일 기록',
                  value: '7일',
                  tone: MetricTone.blue,
                ),
                MetricRowSpec(
                  icon: Icons.access_time_rounded,
                  label: '가장 잘 챙긴 시간대',
                  sublabel: '완료율 92%',
                  value: '오전 8시',
                  tone: MetricTone.purple,
                ),
                MetricRowSpec(
                  icon: Icons.event_available_rounded,
                  label: '총 완료 횟수',
                  sublabel: '이번 주 합계',
                  value: '28회',
                  tone: MetricTone.green,
                ),
              ],
            ),
            WeeklyBarChart(
              bars: _weeklyBars,
              onDetailTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
