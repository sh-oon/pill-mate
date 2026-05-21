import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/dialogs/confirm_action_dialog.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/pill_icon.dart';
import '../../../core/widgets/pill_toggle_switch.dart';
import '../../../core/widgets/search_input_bar.dart';
import '../data/medication_providers.dart';
import '../data/medication_repository.dart';

/// 약 서랍 (rDr) — Drift 기반 실데이터 리스트.
class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  _CategoryFilter _filter = _CategoryFilter.all;
  _MedicationSort _sort = _MedicationSort.name;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(TrackedMedicationWithSchedules m) {
    final cat = m.medication.category;
    return switch (_filter) {
      _CategoryFilter.all => true,
      _CategoryFilter.sup => cat == 'sup',
      _CategoryFilter.med => cat == 'med',
    };
  }

  /// 검색어 substring 매칭 — 약 이름 + 메모 (대소문자 무시).
  bool _matchesQuery(TrackedMedicationWithSchedules m) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final name = m.medication.name.toLowerCase();
    final memo = m.medication.memo?.toLowerCase() ?? '';
    return name.contains(q) || memo.contains(q);
  }

  bool _matches(TrackedMedicationWithSchedules m) =>
      _matchesCategory(m) && _matchesQuery(m);

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_MedicationSort>(
      context: context,
      builder: (ctx) => SafeArea(
        child: RadioGroup<_MedicationSort>(
          groupValue: _sort,
          onChanged: (v) => Navigator.of(ctx).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 18, 22, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '정렬',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ),
              for (final s in _MedicationSort.values)
                RadioListTile<_MedicationSort>(
                  value: s,
                  title: Text(s.label),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != _sort) {
      setState(() => _sort = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(trackedMedicationsStreamProvider);

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
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        error: (e, _) => _ErrorState(error: e),
        data: (all) {
          final filtered = all.where(_matches).toList()
            ..sort(_sort.comparator);
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 140),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                child: SearchInputBar(
                  hintText: '약 이름 또는 메모 검색',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              _FilterRow(
                filter: _filter,
                onChange: (f) => setState(() => _filter = f),
                sortLabel: _sort.label,
                onSortTap: _pickSort,
              ),
              if (all.isEmpty)
                const _EmptyState()
              else if (filtered.isEmpty)
                _EmptyFiltered(query: _query.isNotEmpty ? _query : null)
              else
                for (final m in filtered)
                  _SwipeToDelete(
                    id: m.medication.id,
                    onConfirm: () => ConfirmActionDialog.show(
                      context,
                      title: '${m.medication.name} 삭제',
                      message: '이 약과 모든 복용 기록이\n함께 삭제됩니다. 되돌릴 수 없어요.',
                    ),
                    onDismissed: () async {
                      await ref
                          .read(trackedMedicationRepositoryProvider)
                          .delete(m.medication.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${m.medication.name} 삭제됨'),
                        ),
                      );
                    },
                    child: _MedListCard(
                      data: m,
                      onToggleAlarm: (v) {
                        ref
                            .read(trackedMedicationRepositoryProvider)
                            .setAlarmEnabled(m.medication.id, v);
                      },
                      onTap: () => context.push(
                        AppRoute.drawerDetailPath(m.medication.id),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: AppFab(
        onPressed: () => context.push(AppRoute.drawerNew),
      ),
    );
  }
}

// ============================================================
// 필터 행
// ============================================================

enum _CategoryFilter { all, sup, med }

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.onChange,
    required this.sortLabel,
    required this.onSortTap,
  });

  final _CategoryFilter filter;
  final ValueChanged<_CategoryFilter> onChange;
  final String sortLabel;
  final VoidCallback onSortTap;

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
          _SortChip(label: sortLabel, onTap: onSortTap),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const Icon(Icons.expand_more,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 정렬 옵션
// ============================================================

enum _MedicationSort { name, recent, nextDose }

extension on _MedicationSort {
  String get label => switch (this) {
        _MedicationSort.name => '이름순',
        _MedicationSort.recent => '최근 등록순',
        _MedicationSort.nextDose => '다음 복용순',
      };

  int Function(TrackedMedicationWithSchedules, TrackedMedicationWithSchedules) get comparator =>
      switch (this) {
        _MedicationSort.name => _byName,
        _MedicationSort.recent => _byRecent,
        _MedicationSort.nextDose => _byNextDose,
      };
}

int _byName(TrackedMedicationWithSchedules a, TrackedMedicationWithSchedules b) =>
    a.medication.name.toLowerCase().compareTo(b.medication.name.toLowerCase());

int _byRecent(TrackedMedicationWithSchedules a, TrackedMedicationWithSchedules b) =>
    b.medication.createdAt.compareTo(a.medication.createdAt);

/// PRN(스케줄 없음)은 항상 마지막. 그 외엔 가장 가까운 미래 복용시각 오름차순.
int _byNextDose(TrackedMedicationWithSchedules a, TrackedMedicationWithSchedules b) {
  final na = _nextDoseAt(a);
  final nb = _nextDoseAt(b);
  if (na == null && nb == null) return _byName(a, b);
  if (na == null) return 1;
  if (nb == null) return -1;
  final c = na.compareTo(nb);
  return c != 0 ? c : _byName(a, b);
}

/// 약의 가장 가까운 미래 복용 시각 (오늘 남은 슬롯 있으면 오늘, 아니면 내일 첫
/// 슬롯). PRN(스케줄 없음)이면 null.
DateTime? _nextDoseAt(TrackedMedicationWithSchedules m) {
  if (m.schedules.isEmpty) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mins = now.hour * 60 + now.minute;
  final times = [...m.times]..sort();
  for (final t in times) {
    final parts = t.split(':');
    final tm = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    if (tm > mins) {
      return today.add(Duration(minutes: tm));
    }
  }
  final first = times.first.split(':');
  return today.add(Duration(
    days: 1,
    minutes: int.parse(first[0]) * 60 + int.parse(first[1]),
  ));
}

// ============================================================
// 약 카드 (`.dc`)
// ============================================================

class _MedListCard extends StatelessWidget {
  const _MedListCard({
    required this.data,
    required this.onToggleAlarm,
    required this.onTap,
  });

  final TrackedMedicationWithSchedules data;
  final ValueChanged<bool> onToggleAlarm;
  final VoidCallback onTap;

  bool get _alarmOn => data.schedules.any((s) => s.enabled);

  /// PRN(필요시 복용) = 스케줄 없음.
  bool get _isPrn => data.schedules.isEmpty;

  String get _quantityLabel {
    final m = data.medication;
    final dose = m.dosage;
    final unit = m.unit;
    if (dose != null && unit != null) return '$dose$unit';
    if (dose != null) return dose;
    return '1정';
  }

  String? get _nextDoseLabel {
    if (_isPrn) return null;
    // 가장 가까운 시각을 단순 계산 (오늘/내일).
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    final sorted = [...data.times]..sort();
    String? todayLabel;
    for (final t in sorted) {
      final parts = t.split(':');
      final tm = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (tm > mins) {
        todayLabel = '오늘 $t';
        break;
      }
    }
    return todayLabel ?? '내일 ${sorted.first}';
  }

  @override
  Widget build(BuildContext context) {
    final m = data.medication;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _MedListCardTop(
                name: m.name,
                category: m.category ?? 'sup',
                quantity: _isPrn ? '$_quantityLabel (필요시 복용)' : _quantityLabel,
                alarmOn: _alarmOn,
                onToggleAlarm: onToggleAlarm,
              ),
              const SizedBox(height: 12),
              if (_isPrn)
                const _PrnFooter()
              else
                _NextDoseFooter(time: _nextDoseLabel!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedListCardTop extends StatelessWidget {
  const _MedListCardTop({
    required this.name,
    required this.category,
    required this.quantity,
    required this.alarmOn,
    required this.onToggleAlarm,
  });

  final String name;
  final String category;
  final String quantity;
  final bool alarmOn;
  final ValueChanged<bool> onToggleAlarm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: PillIcon.svg(medName: name, size: 44),
        ),
        const SizedBox(width: 14),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CategoryChip.fromCode(category),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                quantity,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
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

// ============================================================
// 스와이프-투-딜리트 래퍼
// ============================================================

class _SwipeToDelete extends StatefulWidget {
  const _SwipeToDelete({
    required this.id,
    required this.child,
    required this.onConfirm,
    required this.onDismissed,
  });

  final int id;
  final Widget child;
  final Future<bool> Function() onConfirm;
  final VoidCallback onDismissed;

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete>
    with SingleTickerProviderStateMixin {
  late final SlidableController _slc = SlidableController(this);

  @override
  void dispose() {
    _slc.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final ok = await widget.onConfirm();
    if (ok) {
      widget.onDismissed();
    } else {
      await _slc.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Slidable(
          key: ValueKey('med-${widget.id}'),
          controller: _slc,
          groupTag: 'med-list',
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.24,
            dismissible: DismissiblePane(
              confirmDismiss: () async {
                final ok = await widget.onConfirm();
                if (!ok) await _slc.close();
                return ok;
              },
              onDismissed: widget.onDismissed,
            ),
            children: [
              SlidableAction(
                onPressed: (_) => _handleDelete(),
                backgroundColor: AppColors.missed,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline,
                label: '삭제',
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================
// Empty / Error states
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
      child: Column(
        children: const [
          Icon(Icons.medication_outlined, size: 56, color: AppColors.textFaint),
          SizedBox(height: 12),
          Text(
            '등록된 약/영양제가 없습니다',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          SizedBox(height: 4),
          Text(
            '오른쪽 아래 + 버튼으로 추가하세요',
            style: TextStyle(fontSize: 13, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered({this.query});

  /// 검색 결과가 비어있을 때 사용자가 입력한 키워드. null이면 카테고리 필터
  /// 단독으로 결과가 비어있다는 의미.
  final String? query;

  @override
  Widget build(BuildContext context) {
    final text = query != null
        ? '"$query"와(과) 일치하는 약이 없어요'
        : '필터 조건과 일치하는 항목이 없어요';
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 48, 22, 0),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Text(
          '불러오기 실패: $error',
          style: const TextStyle(fontSize: 13, color: AppColors.missed),
        ),
      ),
    );
  }
}
