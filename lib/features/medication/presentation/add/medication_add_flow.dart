import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/tables/schedules.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
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
  String _repeat = 'daily';
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
        .read(medicationRepositoryProvider)
        .getById(widget.medicationId!);
    if (m == null || !mounted) return;
    setState(() {
      _category = m.medication.category ?? 'sup';
      _name = m.medication.name;
      _times
        ..clear()
        ..addAll(m.times);
      if (_times.isEmpty) _times.add('08:00');
      _repeat = switch (m.repeatKind) {
        RepeatKind.daily => 'daily',
        RepeatKind.weekly => 'weekly',
        RepeatKind.interval => 'interval',
      };
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

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = ref.read(medicationRepositoryProvider);
    final draft = MedicationDraft(
      name: _name.trim(),
      category: _category!,
      times: _times,
      repeatKind: switch (_repeat) {
        'weekly' => RepeatKind.weekly,
        'interval' => RepeatKind.interval,
        _ => RepeatKind.daily,
      },
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
      ref.invalidate(medicationsStreamProvider);
      if (_isEdit) {
        ref.invalidate(medicationByIdProvider(widget.medicationId!));
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
        3 => _times.isNotEmpty,
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
          onChange: (v) => setState(() => _name = v),
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
          onAddTime: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
            );
            if (picked != null && _times.length < 8) {
              setState(() {
                final hh = picked.hour.toString().padLeft(2, '0');
                final mm = picked.minute.toString().padLeft(2, '0');
                _times.add('$hh:$mm');
                _times.sort();
              });
            }
          },
        );
    }
  }
}
