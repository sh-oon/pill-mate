import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
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
        .map((d) => BundleMed(name: d.medicationName, quantity: d.quantityLabel))
        .toList();

    await BundleNotificationSheet.show(
      context,
      time: bundle.isEmpty
          ? ''
          : '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
      meds: bundle,
    );
  }

  Future<void> _openEditSheet(
      BuildContext context, DoseInstance dose) async {
    final choice = await EditRecordSheet.show(
      context,
      medName: dose.medicationName,
      category: dose.category ?? 'sup',
      time: dose.timeOfDay,
      yesterday: false,
    );
    if (choice == EditRecordChoice.markTaken) {
      await ref.read(intakeRepositoryProvider).markTaken(
            medicationId: dose.medicationId,
            scheduleId: dose.scheduleId,
            scheduledAt: dose.scheduledAt,
          );
    }
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

    return Container(
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
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '오늘 ${counts.total}개 중\n'),
                          TextSpan(
                            text: '${counts.done}개 완료',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const TextSpan(text: '했어요!'),
                        ],
                      ),
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
                onTap: () => _goToCalendar(context, ref, DayFilter.completed),
              ),
              StatCell(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.primary,
                label: '예정',
                count: counts.pending,
                onTap: () => _goToCalendar(context, ref, DayFilter.scheduled),
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
          if (next != null) _NextDosePill(dose: next),
        ],
      ),
    );
  }
}

class _NextDosePill extends StatelessWidget {
  const _NextDosePill({required this.dose});
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

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.dose,
    required this.showTakeButton,
    required this.onTaken,
  });

  final DoseInstance dose;
  final bool showTakeButton;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        showTakeButton
            ? AppButton(
                label: '먹었어요',
                onPressed: onTaken,
                size: AppButtonSize.sm,
              )
            : StatusBadge(status: _toBadgeStatus(dose.status)),
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
