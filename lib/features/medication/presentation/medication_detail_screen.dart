import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/med_pill_svg.dart';
import '../../../core/widgets/pill_toggle_switch.dart';
import '../../../core/widgets/time_chip.dart';

/// 약 상세 (rDet).
///
/// 더미 fixture로 동작하며 실제 데이터 레이어 연동은 별도 PR.
class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final int medicationId;

  @override
  ConsumerState<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState
    extends ConsumerState<MedicationDetailScreen> {
  late _MedDetail _med;

  @override
  void initState() {
    super.initState();
    _med = _fixtures[widget.medicationId] ?? _fixtures[1]!;
  }

  void _setAlarm(bool v) => setState(() => _med = _med.copyWith(alarm: v));

  @override
  Widget build(BuildContext context) {
    final m = _med;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
          children: [
            _Header(onBack: () => context.pop()),
            _HeroCard(med: m),
            _Section(
              title: '알림',
              rows: [
                _Row(
                  label: '복용 알림',
                  trailing: PillToggleSwitch(
                    value: m.alarm,
                    onChanged: _setAlarm,
                  ),
                ),
                if (!m.prn)
                  _Row(
                    label: '다음 알림',
                    trailing: Text(
                      m.nextAlarmLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            _Section(
              title: '일정',
              rows: [
                _Row(label: '반복', trailing: _ValueText(text: m.repeat)),
                if (!m.prn)
                  _RowColumn(
                    label: '알림 시각',
                    body: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in m.times) TimeChip(time: t),
                      ],
                    ),
                  ),
                _Row(label: '종료일', trailing: const _ValueText(text: '없음')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DangerButton(
                      label: '삭제하기',
                      fullWidth: true,
                      onPressed: () {
                        // TODO: show delete confirm dialog
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: '수정하기',
                      fullWidth: true,
                      onPressed: () {
                        // TODO: navigate to edit (drawer/:id/edit)
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Header (back + title + menu)
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
            color: AppColors.textStrong,
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
          ),
          const Text(
            '약 정보',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
            color: AppColors.textStrong,
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Hero (100×100 pill + name + cat + qty)
// ============================================================

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.med});
  final _MedDetail med;

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
            child: MedPillSvg(name: med.name, size: 72),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  med.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CategoryChip.fromCode(med.category),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            med.prn ? '${med.quantity} · 필요시 복용' : med.quantity,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Section + Row primitives
// ============================================================

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
          Text(
            label,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textStrong),
          ),
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

// ============================================================
// Fixtures
// ============================================================

class _MedDetail {
  const _MedDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.alarm,
    required this.repeat,
    required this.times,
    required this.nextAlarmLabel,
    this.prn = false,
  });

  final int id;
  final String name;
  final String category;
  final String quantity;
  final bool alarm;
  final String repeat;
  final List<String> times;
  final String nextAlarmLabel;
  final bool prn;

  _MedDetail copyWith({bool? alarm}) => _MedDetail(
        id: id,
        name: name,
        category: category,
        quantity: quantity,
        alarm: alarm ?? this.alarm,
        repeat: repeat,
        times: times,
        nextAlarmLabel: nextAlarmLabel,
        prn: prn,
      );
}

const _fixtures = <int, _MedDetail>{
  1: _MedDetail(
    id: 1,
    name: '종합비타민',
    category: 'sup',
    quantity: '1정',
    alarm: true,
    repeat: '매일',
    times: ['08:00'],
    nextAlarmLabel: '내일 08:00',
  ),
  2: _MedDetail(
    id: 2,
    name: '유산균',
    category: 'sup',
    quantity: '1캡슐',
    alarm: true,
    repeat: '매일',
    times: ['08:00'],
    nextAlarmLabel: '오늘 08:00',
  ),
  3: _MedDetail(
    id: 3,
    name: '오메가3',
    category: 'sup',
    quantity: '1캡슐',
    alarm: true,
    repeat: '매일',
    times: ['12:00'],
    nextAlarmLabel: '오늘 12:00',
  ),
  4: _MedDetail(
    id: 4,
    name: '마그네슘',
    category: 'sup',
    quantity: '1정',
    alarm: true,
    repeat: '매일',
    times: ['21:00'],
    nextAlarmLabel: '내일 21:00',
  ),
  5: _MedDetail(
    id: 5,
    name: '비타민D',
    category: 'sup',
    quantity: '1정',
    alarm: true,
    repeat: '매일',
    times: ['09:00'],
    nextAlarmLabel: '내일 09:00',
  ),
  6: _MedDetail(
    id: 6,
    name: '감기약',
    category: 'med',
    quantity: '1정',
    alarm: false,
    repeat: '필요시 복용',
    times: [],
    nextAlarmLabel: '',
    prn: true,
  ),
};
