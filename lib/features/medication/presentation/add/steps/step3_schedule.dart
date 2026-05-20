import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/filter_pill.dart';
import '../widgets/time_slot_row.dart';

/// 사용자가 고를 수 있는 "본 알림 N분 전" 사전 알림 옵션 (분).
/// null이면 사전 알림 OFF.
const kPreReminderOptions = <int?>[null, 5, 10, 15, 30];

/// Step 3: 반복 + 알림 시각 + 사전 알림 입력.
class Step3Schedule extends StatelessWidget {
  const Step3Schedule({
    super.key,
    required this.repeat,
    required this.onChangeRepeat,
    required this.times,
    required this.onRemoveTime,
    required this.onAddTime,
    required this.remindBeforeMinutes,
    required this.onChangeRemindBeforeMinutes,
  });

  final String repeat; // 'daily' | 'weekly' | 'interval'
  final ValueChanged<String> onChangeRepeat;
  final List<String> times;
  final ValueChanged<int> onRemoveTime;
  final VoidCallback onAddTime;

  /// null = 사전 알림 OFF, 그 외엔 본 알림 N분 전.
  final int? remindBeforeMinutes;
  final ValueChanged<int?> onChangeRemindBeforeMinutes;

  @override
  Widget build(BuildContext context) {
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
              if (times.length < 8)
                AddTimeDashedButton(onPressed: onAddTime),
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
