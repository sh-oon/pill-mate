import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/donut_progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _notif;
  bool _dismissed = false;

  // --- 더미 데이터 (실제 데이터 연결 전 시안 재현용) ---
  static const int _doneCount = 2;
  static const int _scheduledCount = 2;
  static const int _missedCount = 1;
  static const int _totalCount = 5;
  static const _nextDose = (time: '12:00', name: '오메가3');
  static const _missed = (
    name: '비타민D',
    category: '영양제',
    scheduledLabel: '어제 21:00에 복용 예정이었어요',
    color: AppColors.pillPink,
    letter: 'D',
  );
  static const _schedule = [
    _TimelineSlot(
      time: '08:00',
      items: [
        _DoseItem(
          name: '종합비타민',
          quantity: '1정',
          color: AppColors.pillYellow,
          status: _DoseStatus.done,
        ),
        _DoseItem(
          name: '유산균',
          quantity: '1캡슐',
          color: AppColors.pillBlue,
          status: _DoseStatus.done,
        ),
      ],
    ),
    _TimelineSlot(
      time: '12:00',
      isNext: true,
      items: [
        _DoseItem(
          name: '오메가3',
          quantity: '1캡슐',
          color: AppColors.pillOrange,
          status: _DoseStatus.upcoming,
        ),
      ],
    ),
    _TimelineSlot(
      time: '21:00',
      items: [
        _DoseItem(
          name: '마그네슘',
          quantity: '1정',
          color: AppColors.pillPurple,
          status: _DoseStatus.scheduled,
        ),
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
            _Header(
              onBellTap: () => context.push(AppRoute.settings),
              hasUnread: true,
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
              category: _missed.category,
              scheduledLabel: _missed.scheduledLabel,
              color: _missed.color,
              letter: _missed.letter,
              onEditRecord: () {},
            ),
            const _ScheduleSectionHeader(),
            for (final slot in _schedule)
              _TimelineRow(slot: slot, onTaken: () {}),
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
// Header
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.onBellTap, required this.hasUnread});

  final VoidCallback onBellTap;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PillMate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 24,
                  color: AppColors.textStrong,
                  onPressed: onBellTap,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (hasUnread)
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.missed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Summary card (lavender)
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
          _StatsRow(done: done, scheduled: scheduled, missed: missed, total: total),
          const SizedBox(height: 14),
          _NextDosePill(time: nextDoseTime, name: nextDoseName),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.done,
    required this.scheduled,
    required this.missed,
    required this.total,
  });

  final int done;
  final int scheduled;
  final int missed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            iconBg: AppColors.primary,
            icon: Icons.check_rounded,
            iconColor: Colors.white,
            isCircleBg: true,
            label: '완료',
            count: done,
          ),
        ),
        Expanded(
          child: _StatCell(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
            label: '예정',
            count: scheduled,
          ),
        ),
        Expanded(
          child: _StatCell(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.missed,
            label: '놓침',
            count: missed,
          ),
        ),
        Expanded(
          child: _StatCell(
            icon: Icons.format_list_bulleted_rounded,
            iconColor: AppColors.textMuted,
            label: '전체',
            count: total,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.iconBg,
    this.isCircleBg = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color? iconBg;
  final bool isCircleBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: isCircleBg
                ? BoxDecoration(color: iconBg, shape: BoxShape.circle)
                : null,
            child: Center(
              child: Icon(icon, size: isCircleBg ? 18 : 24, color: iconColor),
            ),
          ),
          const SizedBox(height: 6),
          const Text(''),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            '$count개',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
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
    required this.category,
    required this.scheduledLabel,
    required this.color,
    required this.letter,
    required this.onEditRecord,
  });

  final String name;
  final String category;
  final String scheduledLabel;
  final Color color;
  final String letter;
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
              _PillIcon(color: color, letter: letter),
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
                        _CategoryChip(label: category),
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
              _EditRecordButton(onTap: onEditRecord),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditRecordButton extends StatelessWidget {
  const _EditRecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.missed,
        side: const BorderSide(color: AppColors.missed, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('기록 수정'),
    );
  }
}

// ============================================================
// Schedule section
// ============================================================

class _ScheduleSectionHeader extends StatelessWidget {
  const _ScheduleSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '오늘의 복용 일정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('전체보기'),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.slot, required this.onTaken});

  final _TimelineSlot slot;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Text(
                    slot.time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MedCard(slot: slot, onTaken: onTaken),
          ),
        ],
      ),
    );
  }
}

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
            _DoseRow(item: slot.items[i], onTaken: onTaken),
          ],
        ],
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.item, required this.onTaken});

  final _DoseItem item;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillIcon(color: item.color),
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
                  const _CategoryChip(label: '영양제'),
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
        switch (item.status) {
          _DoseStatus.done => const _StatusBadge(
              label: '완료',
              bg: AppColors.successTint,
              fg: AppColors.success,
            ),
          _DoseStatus.scheduled => const _StatusBadge(
              label: '예정',
              bg: AppColors.primaryTint,
              fg: AppColors.primary,
            ),
          _DoseStatus.upcoming => _TakenButton(onPressed: onTaken),
        },
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _TakenButton extends StatelessWidget {
  const _TakenButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: const Text('먹었어요'),
    );
  }
}

// ============================================================
// Shared atoms
// ============================================================

class _PillIcon extends StatelessWidget {
  const _PillIcon({required this.color, this.letter});

  final Color color;
  final String? letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: letter == null
            ? null
            : Text(
                letter!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
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
// Data classes (place at end — only used as immutable structs)
// ============================================================

enum _DoseStatus { done, scheduled, upcoming }

class _DoseItem {
  const _DoseItem({
    required this.name,
    required this.quantity,
    required this.color,
    required this.status,
  });

  final String name;
  final String quantity;
  final Color color;
  final _DoseStatus status;
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
