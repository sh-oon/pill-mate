import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/tables/intake_logs.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/donut_progress.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheets/bundle_notification_sheet.dart';
import '../../../core/widgets/sheets/edit_record_sheet.dart';
import '../../../core/widgets/stat_grid_4.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/timeline_row.dart';
import '../../../core/widgets/touchable_badge.dart';
import '../../medication/data/calendar_providers.dart';
import '../../medication/data/intake_providers.dart';
import '../../medication/data/intake_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _notif;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final report = await ref.read(permissionServiceProvider).status();
    if (!mounted) return;
    setState(() => _notif = report.notification);
  }

  bool get _shouldShowBanner =>
      !_dismissed &&
      _notif != null &&
      (_notif!.isDenied || _notif!.isPermanentlyDenied);

  @override
  Widget build(BuildContext context) {
    final dosesAsync = ref.watch(todayDosesProvider);
    final countsAsync = ref.watch(todayCountsProvider);
    final nextDoseAsync = ref.watch(todayNextDoseProvider);
    final missedAsync = ref.watch(recentMissedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            AppTopBar(
              hasUnread: countsAsync.value?.missed != null &&
                  (countsAsync.value!.missed > 0 ||
                      countsAsync.value!.pending > 0),
              onBellTap: () => _openBundleSheet(context, dosesAsync.value),
              onSettingsTap: () => context.push(AppRoute.settings),
            ),
            if (_shouldShowBanner)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _PermissionBanner(
                  permanentlyDenied: _notif!.isPermanentlyDenied,
                  onDismiss: () => setState(() => _dismissed = true),
                  onRequest: () async {
                    if (_notif!.isPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await ref
                          .read(permissionServiceProvider)
                          .requestAll();
                    }
                    await _refreshStatus();
                  },
                ),
              ),
            _SummaryCard(
              countsAsync: countsAsync,
              nextDoseAsync: nextDoseAsync,
            ),
            missedAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (missed) {
                if (missed == null) return const SizedBox.shrink();
                return _MissedDoseCard(
                  dose: missed,
                  onEditRecord: () => _openEditSheet(context, missed),
                );
              },
            ),
            SectionHeader(
              title: '오늘의 복용 일정',
              action: TouchableBadge(
                label: '전체보기',
                trailingIcon: Icons.chevron_right,
                onTap: () {},
              ),
            ),
            _ScheduleSection(dosesAsync: dosesAsync),
          ],
        ),
      ),
      floatingActionButton: AppFab(
        heroTag: 'home_fab',
        onPressed: () => context.push(AppRoute.drawerNew),
      ),
    );
  }

  Future<void> _openBundleSheet(
      BuildContext context, List<DoseInstance>? doses) async {
    // 가장 가까운 미래 시간대 묶음 또는 가장 오래된 missed 묶음
    final now = DateTime.now();
    DateTime? targetTime;
    final pending = doses
            ?.where((d) =>
                d.status == IntakeStatus.pending && d.scheduledAt.isAfter(now))
            .toList() ??
        [];
    final missed =
        doses?.where((d) => d.status == IntakeStatus.missed).toList() ?? [];
    if (pending.isNotEmpty) {
      pending.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      targetTime = pending.first.scheduledAt;
    } else if (missed.isNotEmpty) {
      missed.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      targetTime = missed.first.scheduledAt;
    }

    if (targetTime == null || doses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림으로 묶을 복용 예정이 없어요')),
      );
      return;
    }

    final bundle = doses
        .where((d) => d.scheduledAt == targetTime)
        .map((d) => BundleMed(
              name: d.medicationName,
              quantity: d.quantityLabel,
              scheduleId: d.scheduleId,
              medicationId: d.medicationId,
              scheduledAt: d.scheduledAt,
              alreadyTaken: d.status == IntakeStatus.taken,
            ))
        .toList();

    await BundleNotificationSheet.show(
      context,
      time: bundle.isEmpty
          ? ''
          : '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
      meds: bundle,
      onMarkTaken: (selected) async {
        final repo = ref.read(intakeRepositoryProvider);
        for (final m in selected) {
          await repo.markTaken(
            medicationId: m.medicationId,
            scheduleId: m.scheduleId,
            scheduledAt: m.scheduledAt,
          );
        }
      },
    );
  }

  /// calendar-dose-edit: Calendar와 동일한 sheet props로 정합화.
  /// taken↔missed 양방향 toggle 지원. DB mark 후 invalidate는 StreamProvider
  /// 자동 전파 — 명시 호출 불필요.
  Future<void> _openEditSheet(
      BuildContext context, DoseInstance dose) async {
    final now = DateTime.now();
    if (dose.scheduledAt.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 예정된 복용입니다')),
      );
      return;
    }

    final choice = await EditRecordSheet.show(
      context,
      medName: dose.medicationName,
      category: dose.category ?? 'sup',
      time: dose.timeOfDay,
      dateLabel: _relativeLabel(dose.scheduledAt),
      currentStatus: dose.status,
      allowMissed: true,
    );
    if (!context.mounted) return;

    final repo = ref.read(intakeRepositoryProvider);
    final String feedback;
    try {
      switch (choice) {
        case EditRecordChoice.markTaken:
          await repo.markTaken(
            medicationId: dose.medicationId,
            scheduleId: dose.scheduleId,
            scheduledAt: dose.scheduledAt,
          );
          feedback = "'이미 복용'으로 수정했어요";
        case EditRecordChoice.markMissed:
          await repo.markMissed(
            medicationId: dose.medicationId,
            scheduleId: dose.scheduleId,
            scheduledAt: dose.scheduledAt,
          );
          feedback = "'놓침'으로 수정했어요";
        case EditRecordChoice.keep:
        case null:
          return;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경 실패: $e')),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(feedback)));
  }

  String _relativeLabel(DateTime scheduledAt) {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final d =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final delta = d.difference(t).inDays;
    if (delta == 0) return '오늘';
    if (delta == -1) return '어제';
    if (delta < -1) return '${-delta}일 전';
    return '${scheduledAt.month}월 ${scheduledAt.day}일';
  }
}

// ============================================================
// Summary card
// ============================================================

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.countsAsync,
    required this.nextDoseAsync,
  });

  final AsyncValue<TodayCounts> countsAsync;
  final AsyncValue<DoseInstance?> nextDoseAsync;

  void _goToCalendar(BuildContext context, WidgetRef ref, DayFilter filter) {
    ref.read(calendarFilterProvider.notifier).set(filter);
    ref.read(calendarJumpDateProvider.notifier).set(DateTime.now());
    context.go(AppRoute.calendar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = countsAsync.value ??
        const TodayCounts(done: 0, pending: 0, missed: 0, total: 0);
    final next = nextDoseAsync.value;

    // 카드 진입 시 한 번 fade + slide-up. 부모 rebuild에도 TweenAnimationBuilder
    // 의 widget state가 유지돼 추가 트윈은 발생하지 않음.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘 복용 현황',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AnimatedTodayHeadline(
                        total: counts.total,
                        done: counts.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                DonutProgress(progress: counts.progress),
              ],
            ),
            const SizedBox(height: 18),
            StatGrid4(
              cells: [
                StatCell(
                  icon: Icons.check_rounded,
                  iconColor: AppColors.primary,
                  label: '완료',
                  count: counts.done,
                  filled: true,
                  onTap: () =>
                      _goToCalendar(context, ref, DayFilter.completed),
                ),
                StatCell(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.primary,
                  label: '예정',
                  count: counts.pending,
                  onTap: () =>
                      _goToCalendar(context, ref, DayFilter.scheduled),
                ),
                StatCell(
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.missed,
                  label: '놓침',
                  count: counts.missed,
                  onTap: () => _goToCalendar(context, ref, DayFilter.missed),
                ),
                StatCell(
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: AppColors.textMuted,
                  label: '전체',
                  count: counts.total,
                  onTap: () => _goToCalendar(context, ref, DayFilter.all),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // next가 있을 때만 pill 표시 — 등장/사라짐을 부드럽게.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: next != null
                  ? _NextDosePill(
                      key: ValueKey(
                        'next-${next.scheduleId}-${next.scheduledAt.millisecondsSinceEpoch}',
                      ),
                      dose: next,
                    )
                  : const SizedBox(
                      key: ValueKey('next-empty'),
                      width: double.infinity,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "오늘 N개 중 M개 완료했어요!" 헤드라인 — total/done 숫자가 변경되면 implicit
/// IntTween으로 트윈. RichText 안에 숫자만 트윈하기 위해 WidgetSpan으로 inline.
class _AnimatedTodayHeadline extends StatelessWidget {
  const _AnimatedTodayHeadline({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: AppColors.textStrong,
      height: 1.4,
    );
    const accentStyle = TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      height: 1.4,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    const numStyle = TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: AppColors.textStrong,
      height: 1.4,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '오늘 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _TweenedInt(value: total, style: numStyle),
          ),
          const TextSpan(text: '개 중\n'),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _TweenedInt(value: done, style: accentStyle),
          ),
          const TextSpan(
            text: '개 완료',
            style: TextStyle(color: AppColors.primary),
          ),
          const TextSpan(text: '했어요!'),
        ],
      ),
    );
  }
}

/// IntTween 기반 트윈된 숫자 텍스트.
class _TweenedInt extends StatelessWidget {
  const _TweenedInt({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v', style: style),
    );
  }
}

class _NextDosePill extends StatelessWidget {
  const _NextDosePill({super.key, required this.dose});
  final DoseInstance dose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  '다음 복용',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            dose.timeOfDay,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dose.medicationName,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// ============================================================
// Missed dose banner
// ============================================================

class _MissedDoseCard extends StatelessWidget {
  const _MissedDoseCard({required this.dose, required this.onEditRecord});

  final DoseInstance dose;
  final VoidCallback onEditRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.missedSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.missedBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '놓친 복용',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.missed,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              PillIcon.svg(medName: dose.medicationName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dose.medicationName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CategoryChip.fromCode(dose.category ?? 'sup'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dose.timeOfDay}에 복용 예정이었어요',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: '기록 수정',
                onPressed: onEditRecord,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                style: const AppButtonStyle(
                  foregroundColor: AppColors.missed,
                  borderColor: AppColors.missed,
                  radius: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Schedule section
// ============================================================

class _ScheduleSection extends ConsumerWidget {
  const _ScheduleSection({required this.dosesAsync});

  final AsyncValue<List<DoseInstance>> dosesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return dosesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(22),
        child: Text('일정을 불러오지 못했어요: $e',
            style: const TextStyle(color: AppColors.missed)),
      ),
      data: (doses) {
        if (doses.isEmpty) return const _EmptyToday();
        // 시간 단위로 그룹.
        final grouped = groupBy<DoseInstance, String>(doses, (d) => d.timeOfDay);
        final entries = grouped.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        // 강조 슬롯 결정: 첫 번째 pending+미래 슬롯.
        final now = DateTime.now();
        String? highlightTime;
        for (final e in entries) {
          final hasPendingFuture = e.value.any((d) =>
              d.status == IntakeStatus.pending &&
              d.scheduledAt.isAfter(now));
          if (hasPendingFuture) {
            highlightTime = e.key;
            break;
          }
        }

        return Column(
          children: [
            for (final e in entries)
              TimelineRow(
                time: e.key,
                child: _MedCard(
                  items: e.value,
                  highlight: e.key == highlightTime,
                  onTaken: (dose) async {
                    await ref.read(intakeRepositoryProvider).markTaken(
                          medicationId: dose.medicationId,
                          scheduleId: dose.scheduleId,
                          scheduledAt: dose.scheduledAt,
                        );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.items,
    required this.highlight,
    required this.onTaken,
  });

  final List<DoseInstance> items;
  final bool highlight;
  final ValueChanged<DoseInstance> onTaken;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(highlight ? 13 : 14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
            ],
            _DoseRow(
              dose: items[i],
              showTakeButton: highlight && items[i].status == IntakeStatus.pending,
              onTaken: () => onTaken(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoseRow extends StatefulWidget {
  const _DoseRow({
    required this.dose,
    required this.showTakeButton,
    required this.onTaken,
  });

  final DoseInstance dose;
  final bool showTakeButton;
  final VoidCallback onTaken;

  @override
  State<_DoseRow> createState() => _DoseRowState();
}

class _DoseRowState extends State<_DoseRow> {
  /// 복용 완료 직후 행 배경에 잠깐 success-tint를 깔아 시각 피드백.
  /// Stream 갱신으로 status가 taken으로 바뀌어 버튼→배지로 전환되는 동안에도
  /// 사용자에게 “기록됐다”는 신호.
  bool _flashing = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _handleTaken() {
    // 1) 즉시 햅틱 — 액션 확정 피드백.
    HapticFeedback.lightImpact();
    // 2) 행 success flash 트리거 — Stack 오버레이로 layout 영향 없음.
    setState(() => _flashing = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _flashing = false);
    });
    // 3) 실제 markTaken — Stream이 갱신되면 부모가 rebuild하면서 widget.showTakeButton
    //    이 false로 바뀌고 AnimatedSwitcher가 부드럽게 배지로 전환.
    widget.onTaken();
  }

  @override
  Widget build(BuildContext context) {
    final dose = widget.dose;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Flash overlay — layout에 영향 주지 않게 Stack/Positioned.fill.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashing ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            PillIcon.svg(medName: dose.medicationName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dose.medicationName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CategoryChip.fromCode(dose.category ?? 'sup'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dose.quantityLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 버튼 ↔ 배지 전환을 부드럽게. key로 child identity 명시.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: widget.showTakeButton
                  ? AppButton(
                      key: const ValueKey('take-btn'),
                      label: '먹었어요',
                      onPressed: _handleTaken,
                      size: AppButtonSize.sm,
                    )
                  : StatusBadge(
                      key: ValueKey('badge-${dose.status.name}'),
                      status: _toBadgeStatus(dose.status),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

DoseStatus _toBadgeStatus(IntakeStatus s) => switch (s) {
      IntakeStatus.taken => DoseStatus.done,
      IntakeStatus.pending => DoseStatus.scheduled,
      IntakeStatus.missed => DoseStatus.missed,
      IntakeStatus.skipped => DoseStatus.done,
    };

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        children: const [
          Icon(Icons.event_available_outlined,
              size: 56, color: AppColors.textFaint),
          SizedBox(height: 12),
          Text(
            '오늘 예정된 복용이 없어요',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          SizedBox(height: 4),
          Text(
            '+ 버튼으로 약을 등록해보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Permission banner
// ============================================================

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.permanentlyDenied,
    required this.onDismiss,
    required this.onRequest,
  });

  final bool permanentlyDenied;
  final VoidCallback onDismiss;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.missedSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.missedBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 20, color: AppColors.missed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림이 꺼져 있어요',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  permanentlyDenied
                      ? '설정 앱에서 알림을 켜야 복약 시간을 알려드릴 수 있어요.'
                      : '복약 시간을 놓치지 않게 알림을 허용해주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: permanentlyDenied ? '설정 열기' : '허용하기',
                  onPressed: onRequest,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  style: const AppButtonStyle(
                    foregroundColor: AppColors.missed,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '닫기',
            iconSize: 18,
            color: AppColors.textMuted,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
