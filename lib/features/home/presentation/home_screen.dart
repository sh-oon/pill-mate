import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/donut_progress.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_grid_4.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/timeline_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _notif;
  bool _dismissed = false;

  // --- 더미 데이터 (시안 재현용) ---
  static const int _doneCount = 2;
  static const int _scheduledCount = 2;
  static const int _missedCount = 1;
  static const int _totalCount = 5;
  static const _nextDose = (time: '12:00', name: '오메가3');
  static const _missed = (
    name: '비타민D',
    scheduledLabel: '어제 21:00에 복용 예정이었어요',
  );
  static const _schedule = [
    _TimelineSlot(
      time: '08:00',
      items: [
        _DoseItem(name: '종합비타민', quantity: '1정', status: DoseStatus.done),
        _DoseItem(name: '유산균', quantity: '1캡슐', status: DoseStatus.done),
      ],
    ),
    _TimelineSlot(
      time: '12:00',
      isNext: true,
      items: [
        _DoseItem(name: '오메가3', quantity: '1캡슐', status: DoseStatus.scheduled),
      ],
    ),
    _TimelineSlot(
      time: '21:00',
      items: [
        _DoseItem(name: '마그네슘', quantity: '1정', status: DoseStatus.scheduled),
      ],
    ),
  ];

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
    final progress = _totalCount == 0 ? 0.0 : _doneCount / _totalCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            AppTopBar(
              hasUnread: true,
              onBellTap: () => context.push(AppRoute.settings),
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
              progress: progress,
              done: _doneCount,
              scheduled: _scheduledCount,
              missed: _missedCount,
              total: _totalCount,
              nextDoseTime: _nextDose.time,
              nextDoseName: _nextDose.name,
            ),
            _MissedDoseCard(
              name: _missed.name,
              scheduledLabel: _missed.scheduledLabel,
              onEditRecord: () {},
            ),
            SectionHeader(
              title: '오늘의 복용 일정',
              action: OutlinePillButton(
                label: '전체보기',
                onPressed: () {},
                trailingIcon: Icons.chevron_right,
                compact: true,
              ),
            ),
            for (final slot in _schedule)
              TimelineRow(
                time: slot.time,
                child: _MedCard(slot: slot, onTaken: () {}),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoute.drawerNew),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

// ============================================================
// Summary card
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.progress,
    required this.done,
    required this.scheduled,
    required this.missed,
    required this.total,
    required this.nextDoseTime,
    required this.nextDoseName,
  });

  final double progress;
  final int done;
  final int scheduled;
  final int missed;
  final int total;
  final String nextDoseTime;
  final String nextDoseName;

  @override
  Widget build(BuildContext context) {
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
                          TextSpan(text: '오늘 $total개 중\n'),
                          TextSpan(
                            text: '$done개 완료',
                            style: const TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: '했어요!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DonutProgress(progress: progress),
            ],
          ),
          const SizedBox(height: 18),
          StatGrid4(
            cells: [
              StatCell(
                icon: Icons.check_rounded,
                iconColor: AppColors.primary,
                label: '완료',
                count: done,
                filled: true,
              ),
              StatCell(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.primary,
                label: '예정',
                count: scheduled,
              ),
              StatCell(
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.missed,
                label: '놓침',
                count: missed,
              ),
              StatCell(
                icon: Icons.format_list_bulleted_rounded,
                iconColor: AppColors.textMuted,
                label: '전체',
                count: total,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _NextDosePill(time: nextDoseTime, name: nextDoseName),
        ],
      ),
    );
  }
}

class _NextDosePill extends StatelessWidget {
  const _NextDosePill({required this.time, required this.name});

  final String time;
  final String name;

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
            time,
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
              name,
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
  const _MissedDoseCard({
    required this.name,
    required this.scheduledLabel,
    required this.onEditRecord,
  });

  final String name;
  final String scheduledLabel;
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
              PillIcon.svg(medName: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const CategoryChip(label: '영양제'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduledLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinePillButton(
                label: '기록 수정',
                onPressed: onEditRecord,
                color: AppColors.missed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Schedule timeline rows
// ============================================================

class _MedCard extends StatelessWidget {
  const _MedCard({required this.slot, required this.onTaken});

  final _TimelineSlot slot;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    final highlight = slot.isNext;
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
          for (var i = 0; i < slot.items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
            ],
            _DoseRow(
              item: slot.items[i],
              showTakeButton: slot.isNext,
              onTaken: onTaken,
            ),
          ],
        ],
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.item,
    required this.showTakeButton,
    required this.onTaken,
  });

  final _DoseItem item;

  /// 강조 슬롯에 속하면 상태 배지 대신 "먹었어요" 버튼 노출.
  final bool showTakeButton;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PillIcon.svg(medName: item.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.name,
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
                item.quantity,
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
            ? PrimaryButton(
                label: '먹었어요',
                onPressed: onTaken,
                size: AppButtonSize.sm,
              )
            : StatusBadge(status: item.status),
      ],
    );
  }
}

// ============================================================
// Permission banner (denied notifications)
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
                TextButton(
                  onPressed: onRequest,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    foregroundColor: AppColors.missed,
                  ),
                  child: Text(permanentlyDenied ? '설정 열기' : '허용하기'),
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

// ============================================================
// Data classes
// ============================================================

class _DoseItem {
  const _DoseItem({
    required this.name,
    required this.quantity,
    required this.status,
  });

  final String name;
  final String quantity;
  final DoseStatus status;
}

class _TimelineSlot {
  const _TimelineSlot({
    required this.time,
    required this.items,
    this.isNext = false,
  });

  final String time;
  final List<_DoseItem> items;
  final bool isNext;
}
