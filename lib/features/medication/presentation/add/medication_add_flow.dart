import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
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

  void _finish() {
    // TODO: persist via data layer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등록되었어요')),
    );
    context.pop();
  }

  bool get _canProceed => switch (_step) {
        1 => _category != null,
        2 => _name.trim().isNotEmpty,
        3 => _times.isNotEmpty,
        _ => false,
      };

  String get _nextLabel => _step == 3 ? '등록 완료' : '다음';

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
                onPressed: _canProceed ? _next : null,
                size: AppButtonSize.lg,
                fullWidth: true,
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
