import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/tables/schedules.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/sheets/time_picker_sheet.dart';
import '../../data/intake_providers.dart';
import '../../data/medication_providers.dart';
import '../../data/medication_repository.dart';
import 'steps/step1_category.dart';
import 'steps/step2_name.dart';
import 'steps/step3_schedule.dart';
import 'widgets/step_progress_header.dart';

/// 약 추가 3단계 위저드 (rAdd).
///
/// 편집 모드(`medicationId != null`)일 땐 fixture 값을 prefill해서 시작 가능
/// (실데이터 연동은 별도 PR).
class MedicationAddFlow extends ConsumerStatefulWidget {
  const MedicationAddFlow({super.key, this.medicationId});

  final int? medicationId;

  @override
  ConsumerState<MedicationAddFlow> createState() => _MedicationAddFlowState();
}

class _MedicationAddFlowState extends ConsumerState<MedicationAddFlow> {
  int _step = 1;
  String? _category; // 'med' | 'sup'
  String _name = '';
  String _dosage = '';
  String _unit = '';
  String _memo = '';
  String _repeat = 'daily';
  // 요일 마스크 — bit 0=일 ... 6=토. weekly가 아닌 모드에서는 무시.
  // 기본값: 평일(월~금) = bit 1..5 = 0b0111110 = 62.
  int _daysOfWeekMask = 62;
  // N일 간격 — interval 모드에서 사용. 기본 2.
  int _intervalDays = 2;
  final List<String> _times = ['08:00'];
  int? _remindBeforeMinutes; // null = 사전 알림 OFF
  bool _saving = false;

  bool get _isEdit => widget.medicationId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefillFromExisting();
  }

  Future<void> _prefillFromExisting() async {
    final m = await ref
        .read(trackedMedicationRepositoryProvider)
        .getById(widget.medicationId!);
    if (m == null || !mounted) return;
    setState(() {
      _category = m.medication.category ?? 'sup';
      _name = m.medication.name;
      _dosage = m.medication.dosage ?? m.catalog?.defaultDosage ?? '';
      _unit = m.medication.unit ?? m.catalog?.defaultUnit ?? '';
      _memo = m.medication.memo ?? '';
      // legacy DB에 중복 시각이 있을 수 있어 prefill 시 dedup.
      _times
        ..clear()
        ..addAll(m.times.toSet().toList()..sort());
      if (_times.isEmpty) _times.add('08:00');
      _repeat = switch (m.repeatKind) {
        RepeatKind.daily => 'daily',
        RepeatKind.weekly => 'weekly',
        RepeatKind.interval => 'interval',
      };
      // weekly/interval prefill — 첫 스케줄 기준 (모든 스케줄 동일하다는 전제).
      if (m.schedules.isNotEmpty) {
        final first = m.schedules.first;
        if (first.daysOfWeekMask != null && first.daysOfWeekMask! > 0) {
          _daysOfWeekMask = first.daysOfWeekMask!;
        }
        if (first.intervalDays != null && first.intervalDays! > 0) {
          _intervalDays = first.intervalDays!;
        }
      }
      final rem = m.remindBeforeMinutes;
      _remindBeforeMinutes = (rem == null || rem <= 0) ? null : rem;
    });
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step -= 1);
    } else {
      context.pop();
    }
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  /// "HH:mm" 시각을 _times에 추가. 이미 있으면 silent skip (중복 방지).
  /// 8개 cap 도달 시 SnackBar 안내.
  void _addUniqueTime(String hhmm) {
    if (_times.contains(hhmm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 $hhmm 알람이 있어요')),
      );
      return;
    }
    if (_times.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알람 시각은 최대 8개')),
      );
      return;
    }
    setState(() {
      _times.add(hhmm);
      _times.sort();
    });
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = ref.read(trackedMedicationRepositoryProvider);
    final repeatKind = switch (_repeat) {
      'weekly' => RepeatKind.weekly,
      'interval' => RepeatKind.interval,
      _ => RepeatKind.daily,
    };
    final draft = TrackedMedicationDraft(
      name: _name.trim(),
      category: _category!,
      dosage: _dosage.trim().isEmpty ? null : _dosage.trim(),
      unit: _unit.trim().isEmpty ? null : _unit.trim(),
      memo: _memo.trim().isEmpty ? null : _memo.trim(),
      times: _times,
      repeatKind: repeatKind,
      // weekly만 mask 저장. daily/interval은 null.
      daysOfWeekMask:
          repeatKind == RepeatKind.weekly ? _daysOfWeekMask : null,
      // interval만 days 저장.
      intervalDays:
          repeatKind == RepeatKind.interval ? _intervalDays : null,
      remindBeforeMinutes: _remindBeforeMinutes,
    );
    try {
      if (_isEdit) {
        await repo.updateWithSchedules(widget.medicationId!, draft);
      } else {
        await repo.insertWithSchedules(draft);
      }
      // 명시적 invalidate — stream re-emit이 timing 이슈로 누락되거나
      // 늦게 도착할 때 UI가 stale 데이터를 보여주는 케이스 방어.
      ref.invalidate(todayLogsProvider);
      ref.invalidate(trackedMedicationsStreamProvider);
      if (_isEdit) {
        ref.invalidate(trackedMedicationByIdProvider(widget.medicationId!));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '수정되었어요' : '등록되었어요')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  bool get _canProceed => switch (_step) {
        1 => _category != null,
        2 => _name.trim().isNotEmpty,
        // weekly는 요일 1개 이상 선택해야 진행.
        3 => _times.isNotEmpty &&
            (_repeat != 'weekly' || _daysOfWeekMask != 0),
        _ => false,
      };

  String get _nextLabel => _step == 3 ? (_isEdit ? '수정 완료' : '등록 완료') : '다음';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StepProgressHeader(
              step: _step,
              total: 3,
              onLeading: _back,
            ),
            Expanded(
              child: _buildStepBody(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: AppButton(
                label: _nextLabel,
                onPressed: _canProceed && !_saving ? _next : null,
                size: AppButtonSize.lg,
                fullWidth: true,
                loading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 1:
        return Step1Category(
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        );
      case 2:
        return Step2Name(
          isSupplement: _category == 'sup',
          name: _name,
          dosage: _dosage,
          unit: _unit,
          memo: _memo,
          onChange: (v) => setState(() => _name = v),
          onChangeDosage: (v) => setState(() => _dosage = v),
          onChangeUnit: (v) => setState(() => _unit = v),
          onChangeMemo: (v) => setState(() => _memo = v),
          // 자동완성 픽 시 catalog default 값으로 prefill — 사용자가 이미 입력한
          // 값은 덮어쓰지 않음.
          onPickCatalog: (item) => setState(() {
            if (_dosage.isEmpty && item.defaultDosage != null) {
              _dosage = item.defaultDosage!;
            }
            if (_unit.isEmpty && item.defaultUnit != null) {
              _unit = item.defaultUnit!;
            }
          }),
        );
      case 3:
      default:
        return Step3Schedule(
          repeat: _repeat,
          onChangeRepeat: (r) => setState(() => _repeat = r),
          times: _times,
          onRemoveTime: (i) => setState(() => _times.removeAt(i)),
          remindBeforeMinutes: _remindBeforeMinutes,
          onChangeRemindBeforeMinutes: (m) =>
              setState(() => _remindBeforeMinutes = m),
          daysOfWeekMask: _daysOfWeekMask,
          onChangeDaysOfWeekMask: (v) => setState(() => _daysOfWeekMask = v),
          intervalDays: _intervalDays,
          onChangeIntervalDays: (v) => setState(() => _intervalDays = v),
          onAddPresetTime: _addUniqueTime,
          onAddTime: () async {
            final picked = await showWheelTimePickerSheet(context);
            if (picked == null) return;
            final hh = picked.hour.toString().padLeft(2, '0');
            final mm = picked.minute.toString().padLeft(2, '0');
            _addUniqueTime('$hh:$mm');
          },
        );
    }
  }
}
