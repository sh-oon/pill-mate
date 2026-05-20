import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/tables/schedules.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/dialogs/confirm_action_dialog.dart';
import '../../../core/widgets/med_pill_svg.dart';
import '../../../core/widgets/pill_toggle_switch.dart';
import '../../../core/widgets/time_chip.dart';
import '../data/medication_providers.dart';
import '../data/medication_repository.dart';

class MedicationDetailScreen extends ConsumerWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final int medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicationByIdProvider(medicationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          error: (e, _) => Center(
            child: Text('불러오기 실패: $e',
                style: const TextStyle(color: AppColors.missed)),
          ),
          data: (data) {
            if (data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('이미 삭제된 약입니다.'),
                    const SizedBox(height: 8),
                    AppButton(
                      label: '돌아가기',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              );
            }
            return _DetailBody(data: data);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.data});
  final MedicationWithSchedules data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = data.medication;
    final isPrn = data.schedules.isEmpty;
    final alarmOn = data.schedules.any((s) => s.enabled);
    final times = data.times;
    final firstSchedule = data.schedules.isEmpty ? null : data.schedules.first;
    final remindBefore = firstSchedule?.remindBeforeMinutes ?? 0;
    final endDate = firstSchedule?.endDate;
    final memo = m.memo?.trim();
    final hasMemo = memo != null && memo.isNotEmpty;

    String quantity() {
      final d = m.dosage, u = m.unit;
      if (d != null && u != null) return '$d$u';
      if (d != null) return d;
      return '1정';
    }

    String nextLabel() {
      if (times.isEmpty) return '필요시 복용';
      final now = DateTime.now();
      final mins = now.hour * 60 + now.minute;
      for (final t in times) {
        final p = t.split(':');
        final tm = int.parse(p[0]) * 60 + int.parse(p[1]);
        if (tm > mins) return '오늘 $t';
      }
      return '내일 ${times.first}';
    }

    String repeatLabel() {
      if (isPrn) return '필요시 복용';
      return switch (data.repeatKind) {
        RepeatKind.daily => '매일',
        RepeatKind.weekly => '요일별',
        RepeatKind.interval => 'N일 간격',
      };
    }

    String endDateLabel() {
      if (endDate == null) return '없음';
      final y = endDate.year, mo = endDate.month, d = endDate.day;
      return '$y.${mo.toString().padLeft(2, '0')}.${d.toString().padLeft(2, '0')}';
    }

    String remindBeforeLabel() {
      if (remindBefore <= 0) return '안 함';
      return '$remindBefore분 전';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
      children: [
        _Header(onBack: () => context.pop()),
        _HeroCard(
          name: m.name,
          category: m.category ?? 'sup',
          quantityLabel: isPrn ? '${quantity()} · 필요시 복용' : quantity(),
        ),
        _Section(
          title: '알림',
          rows: [
            _Row(
              label: '복용 알림',
              trailing: PillToggleSwitch(
                value: alarmOn,
                onChanged: (v) {
                  ref
                      .read(medicationRepositoryProvider)
                      .setAlarmEnabled(m.id, v);
                },
              ),
            ),
            if (!isPrn)
              _Row(
                label: '다음 알림',
                trailing: Text(
                  nextLabel(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            if (!isPrn)
              _Row(
                label: '사전 알림',
                trailing: _ValueText(text: remindBeforeLabel()),
              ),
          ],
        ),
        _Section(
          title: '일정',
          rows: [
            _Row(label: '반복', trailing: _ValueText(text: repeatLabel())),
            if (!isPrn)
              _RowColumn(
                label: '알림 시각',
                body: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final t in times) TimeChip(time: t)],
                ),
              ),
            _Row(label: '종료일', trailing: _ValueText(text: endDateLabel())),
          ],
        ),
        if (hasMemo)
          _Section(
            title: '메모',
            rows: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  memo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textStrong,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '삭제하기',
                  variant: AppButtonVariant.danger,
                  fullWidth: true,
                  onPressed: () async {
                    final ok = await ConfirmActionDialog.show(
                      context,
                      title: '${m.name} 삭제',
                      message: '이 약과 모든 복용 기록이\n함께 삭제됩니다. 되돌릴 수 없어요.',
                    );
                    if (!context.mounted) return;
                    if (ok) {
                      await ref
                          .read(medicationRepositoryProvider)
                          .delete(m.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${m.name} 삭제됨')),
                      );
                      context.pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: '수정하기',
                  fullWidth: true,
                  onPressed: () => context.push(
                    '${AppRoute.drawer}/${m.id}/edit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 시각용 sub-widgets
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
              color: AppColors.textStrong,
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          const Text(
            '약 정보',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.category,
    required this.quantityLabel,
  });

  final String name;
  final String category;
  final String quantityLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: MedPillSvg(name: name, size: 72),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CategoryChip.fromCode(category),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quantityLabel,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing});
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textStrong),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _RowColumn extends StatelessWidget {
  const _RowColumn({required this.label, required this.body});
  final String label;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textStrong)),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
