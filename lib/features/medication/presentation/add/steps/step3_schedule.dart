import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/filter_pill.dart';
import '../../../data/medication_providers.dart';
import '../widgets/time_slot_row.dart';

/// 사용자가 고를 수 있는 "본 알림 N분 전" 사전 알림 옵션 (분).
/// null이면 사전 알림 OFF.
const kPreReminderOptions = <int?>[null, 5, 10, 15, 30];

/// Step 3: 반복 + 알림 시각 + 사전 알림 입력.
class Step3Schedule extends ConsumerWidget {
  const Step3Schedule({
    super.key,
    required this.repeat,
    required this.onChangeRepeat,
    required this.times,
    required this.onAddPresetTime,
    required this.onRemoveTime,
    required this.onAddTime,
    required this.remindBeforeMinutes,
    required this.onChangeRemindBeforeMinutes,
    required this.daysOfWeekMask,
    required this.onChangeDaysOfWeekMask,
    required this.intervalDays,
    required this.onChangeIntervalDays,
  });

  final String repeat; // 'daily' | 'weekly' | 'interval'
  final ValueChanged<String> onChangeRepeat;
  final List<String> times;
  final ValueChanged<int> onRemoveTime;
  final VoidCallback onAddTime;

  /// 기존 알람 시간 chip 탭 시 호출. dedup은 caller 책임.
  final ValueChanged<String> onAddPresetTime;

  /// null = 사전 알림 OFF, 그 외엔 본 알림 N분 전.
  final int? remindBeforeMinutes;
  final ValueChanged<int?> onChangeRemindBeforeMinutes;

  /// 요일 비트마스크 — bit 0=일, 1=월 ... 6=토. weekly일 때만 유효.
  final int daysOfWeekMask;
  final ValueChanged<int> onChangeDaysOfWeekMask;

  /// N일 간격 — interval일 때만 유효. 최소 1.
  final int intervalDays;
  final ValueChanged<int> onChangeIntervalDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 다른 약들이 쓰는 알람 시간 중 현재 draft에 아직 안 들어간 것만 chip으로.
    final existing = ref.watch(existingAlarmTimesProvider).value ?? const [];
    final suggestions = [
      for (final t in existing)
        if (!times.contains(t)) t,
    ];
    return ListView(
      children: [
        const _Header(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '반복',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilterPill(
                    label: '매일',
                    selected: repeat == 'daily',
                    onTap: () => onChangeRepeat('daily'),
                  ),
                  FilterPill(
                    label: '요일별',
                    selected: repeat == 'weekly',
                    onTap: () => onChangeRepeat('weekly'),
                  ),
                  FilterPill(
                    label: 'N일 간격',
                    selected: repeat == 'interval',
                    onTap: () => onChangeRepeat('interval'),
                  ),
                ],
              ),
              // repeat 종류별 sub-field.
              if (repeat == 'weekly') ...[
                const SizedBox(height: 14),
                _WeekdayPicker(
                  mask: daysOfWeekMask,
                  onChange: onChangeDaysOfWeekMask,
                ),
              ] else if (repeat == 'interval') ...[
                const SizedBox(height: 14),
                _IntervalDayPicker(
                  days: intervalDays,
                  onChange: onChangeIntervalDays,
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                '알림 시각 · 최대 8개',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < times.length; i++)
                TimeSlotRow(
                  time: times[i],
                  onRemove: () => onRemoveTime(i),
                ),
              if (suggestions.isNotEmpty && times.length < 8) ...[
                const SizedBox(height: 10),
                _ExistingTimesRow(
                  times: suggestions,
                  onTap: onAddPresetTime,
                ),
              ],
              if (times.length < 8) ...[
                const SizedBox(height: 6),
                AddTimeDashedButton(onPressed: onAddTime),
              ],
              const SizedBox(height: 22),
              const Text(
                '사전 알림',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '본 알림 전에 미리 알려드려요',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textFaint,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in kPreReminderOptions)
                    FilterPill(
                      label: m == null ? '안 함' : '$m분 전',
                      selected: remindBeforeMinutes == m,
                      onTap: () => onChangeRemindBeforeMinutes(m),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
                height: 1.3,
              ),
              children: [
                TextSpan(text: '언제\n'),
                TextSpan(
                  text: '알려드릴까요?',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '시간은 직접 정해주세요',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// 다른 약들이 이미 쓰는 알람 시각 chip row.
///
/// 같은 시각을 골라서 약을 묶어 알림 받을 수 있게. 본 약 등록 후 home/calendar의
/// dose bundle 묶음에 합류.
class _ExistingTimesRow extends StatelessWidget {
  const _ExistingTimesRow({required this.times, required this.onTap});

  final List<String> times;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기존 알람에 묶기',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textFaint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in times)
              InkWell(
                onTap: () => onTap(t),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        t,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 요일 선택 — bit 0=일, 1=월 ... 6=토.
/// IntakeRepository.isScheduleActiveOn weekly 분기와 동일한 비트 매핑.
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.mask, required this.onChange});

  final int mask;
  final ValueChanged<int> onChange;

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  void _toggle(int bit) {
    final next = mask ^ (1 << bit);
    onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요일',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _WeekdayChip(
                  label: _labels[i],
                  selected: (mask & (1 << i)) != 0,
                  // 일/토 색상 힌트 (선택 안 됐을 때만 텍스트 색만 살짝).
                  accentColor: i == 0
                      ? AppColors.missed
                      : (i == 6 ? AppColors.primary : null),
                  onTap: () => _toggle(i),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : (accentColor ?? AppColors.textStrong);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// N일 간격 — 숫자 입력. 1~30 범위로 clamp.
class _IntervalDayPicker extends StatefulWidget {
  const _IntervalDayPicker({required this.days, required this.onChange});

  final int days;
  final ValueChanged<int> onChange;

  static const _min = 1;
  static const _max = 30;

  @override
  State<_IntervalDayPicker> createState() => _IntervalDayPickerState();
}

class _IntervalDayPickerState extends State<_IntervalDayPicker> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.days.toString());

  @override
  void didUpdateWidget(covariant _IntervalDayPicker old) {
    super.didUpdateWidget(old);
    // 외부 값이 바뀌었고 사용자 입력 중이 아닐 때만 동기화.
    final external = widget.days.toString();
    if (widget.days != old.days && _ctrl.text != external) {
      _ctrl.text = external;
      _ctrl.selection =
          TextSelection.collapsed(offset: external.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    final clamped =
        parsed.clamp(_IntervalDayPicker._min, _IntervalDayPicker._max);
    widget.onChange(clamped);
    // clamp 결과가 입력값과 다르면 textfield도 보정.
    if (clamped != parsed) {
      _ctrl.text = clamped.toString();
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '간격',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
                onChanged: _commit,
                decoration: InputDecoration(
                  hintText: '2',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '일마다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textStrong,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '1 ~ 30 사이로 입력',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
