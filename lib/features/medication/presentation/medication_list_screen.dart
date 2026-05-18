import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/dialogs/confirm_action_dialog.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/pill_toggle_switch.dart';
import '../../../core/widgets/search_input_bar.dart';

/// 약 서랍 (rDr) — 검색/필터 + 약 카드 리스트.
class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  // --- 더미 데이터 (시안 fixture와 동일) ---
  static const _meds = <_MedFixture>[
    _MedFixture(
        id: 1,
        name: '종합비타민',
        category: 'sup',
        quantity: '1정',
        alarm: true,
        nextDose: '내일 08:00'),
    _MedFixture(
        id: 2,
        name: '유산균',
        category: 'sup',
        quantity: '1캡슐',
        alarm: true,
        nextDose: '오늘 08:00'),
    _MedFixture(
        id: 3,
        name: '오메가3',
        category: 'sup',
        quantity: '1캡슐',
        alarm: true,
        nextDose: '오늘 12:00'),
    _MedFixture(
        id: 4,
        name: '마그네슘',
        category: 'sup',
        quantity: '1정',
        alarm: true,
        nextDose: '내일 21:00'),
    _MedFixture(
        id: 5,
        name: '비타민D',
        category: 'sup',
        quantity: '1정',
        alarm: true,
        nextDose: '내일 09:00'),
    _MedFixture(
        id: 6,
        name: '감기약',
        category: 'med',
        quantity: '1정',
        alarm: false,
        prn: true),
  ];

  // 필터 상태 (전체/영양제/약).
  _CategoryFilter _filter = _CategoryFilter.all;
  // 토글 로컬 오버라이드 (메모리만).
  final Map<int, bool> _alarmOverrides = {};

  List<_MedFixture> get _filteredMeds {
    return _meds.where((m) {
      switch (_filter) {
        case _CategoryFilter.all:
          return true;
        case _CategoryFilter.sup:
          return m.category == 'sup';
        case _CategoryFilter.med:
          return m.category == 'med';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('약 서랍'),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoute.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 140),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
            child: SearchInputBar(hintText: '약 이름 또는 성분명 검색'),
          ),
          _FilterRow(
            filter: _filter,
            onChange: (f) => setState(() => _filter = f),
          ),
          for (final m in _filteredMeds)
            _MedListCard(
              med: m,
              alarmOverride: _alarmOverrides[m.id],
              onToggleAlarm: (v) =>
                  setState(() => _alarmOverrides[m.id] = v),
              onTap: () => context.push(AppRoute.drawerDetailPath(m.id)),
              onDelete: () async {
                final ok = await ConfirmActionDialog.show(
                  context,
                  title: '${m.name} 삭제',
                  message: '이 약과 모든 복용 기록이\n함께 삭제됩니다. 되돌릴 수 없어요.',
                );
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${m.name} 삭제됨')),
                  );
                }
              },
            ),
        ],
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
// 필터 행
// ============================================================

enum _CategoryFilter { all, sup, med }

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChange});

  final _CategoryFilter filter;
  final ValueChanged<_CategoryFilter> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Row(
        children: [
          FilterPill(
            label: '전체',
            selected: filter == _CategoryFilter.all,
            onTap: () => onChange(_CategoryFilter.all),
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '영양제',
            selected: filter == _CategoryFilter.sup,
            onTap: () => onChange(_CategoryFilter.sup),
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '약',
            selected: filter == _CategoryFilter.med,
            onTap: () => onChange(_CategoryFilter.med),
          ),
          const Spacer(),
          const _SortChip(),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '이름순',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Icon(Icons.expand_more,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 약 카드 (`.dc`)
// ============================================================

class _MedListCard extends StatelessWidget {
  const _MedListCard({
    required this.med,
    required this.alarmOverride,
    required this.onToggleAlarm,
    required this.onTap,
    required this.onDelete,
  });

  final _MedFixture med;
  final bool? alarmOverride;
  final ValueChanged<bool> onToggleAlarm;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  bool get _alarmOn => alarmOverride ?? med.alarm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _MedListCardTop(
                    med: med,
                    alarmOn: _alarmOn,
                    onToggleAlarm: onToggleAlarm,
                  ),
                  const SizedBox(height: 12),
                  if (med.prn)
                    const _PrnFooter()
                  else
                    _NextDoseFooter(time: med.nextDose ?? '내일'),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 32,
          child: _DeleteCornerButton(onTap: onDelete),
        ),
      ],
    );
  }
}

class _MedListCardTop extends StatelessWidget {
  const _MedListCardTop({
    required this.med,
    required this.alarmOn,
    required this.onToggleAlarm,
  });

  final _MedFixture med;
  final bool alarmOn;
  final ValueChanged<bool> onToggleAlarm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 56x56 큰 약 아이콘 (`.dp`).
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: PillIcon.svg(medName: med.name, size: 44),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 32), // 우측 삭제버튼 여백
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CategoryChip.fromCode(med.category),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  med.prn ? '${med.quantity} (필요시 복용)' : med.quantity,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        PillToggleSwitch(value: alarmOn, onChanged: onToggleAlarm),
      ],
    );
  }
}

class _NextDoseFooter extends StatelessWidget {
  const _NextDoseFooter({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            '다음 복용:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right,
              size: 16, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

class _PrnFooter extends StatelessWidget {
  const _PrnFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 16, color: AppColors.textFaint),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '알림 없음 · 필요시 복용',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '종료됨',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteCornerButton extends StatelessWidget {
  const _DeleteCornerButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ============================================================
// 데이터 (fixture)
// ============================================================

class _MedFixture {
  const _MedFixture({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.alarm,
    this.prn = false,
    this.nextDose,
  });

  final int id;
  final String name;
  final String category; // 'sup' | 'med'
  final String quantity;
  final bool alarm;
  final bool prn;
  final String? nextDose;
}
