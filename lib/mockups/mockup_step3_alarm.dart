import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_buttons.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — Step 3: 알람 설정 (skip 가능).
///
/// **핵심**: "건너뛰기" 버튼으로 알람 없이 tracked만 등록 가능.
class MockupStep3Alarm extends StatefulWidget {
  const MockupStep3Alarm({super.key});

  @override
  State<MockupStep3Alarm> createState() => _MockupStep3AlarmState();
}

class _MockupStep3AlarmState extends State<MockupStep3Alarm> {
  final List<String> _times = ['08:00'];
  String _repeat = 'daily';

  @override
  Widget build(BuildContext context) {
    return MockupScaffold(
      label: 'Phase 3 · Step 3 — 알람 (skip 가능)',
      child: Column(
        children: [
          // 진행 표시.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const _StepIndicator(current: 3, total: 3),
                const Spacer(),
                Text('3/3', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
                const SizedBox(height: 6),
                Text(
                  '나중에 설정하고 싶으면 건너뛰어도 돼요.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                _SectionHeader(label: '복용 시각'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _times) _TimeChip(time: t),
                    _AddTimeChip(onTap: () {
                      setState(() => _times.add('12:00'));
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(label: '반복'),
                const SizedBox(height: 10),
                Column(
                  children: [
                    for (final r in const [
                      ('daily', '매일'),
                      ('weekly', '특정 요일'),
                      ('interval', 'N일마다'),
                    ])
                      _RadioRow(
                        label: r.$2,
                        selected: _repeat == r.$1,
                        onTap: () => setState(() => _repeat = r.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(label: '사전 알림 (선택)'),
                const SizedBox(height: 10),
                _DropdownLike(value: '없음'),
              ],
            ),
          ),
          // 하단 액션 — 가로 2개 (건너뛰기 / 완료).
          // 화면 상단 "나중에 설정하고 싶으면 건너뛰어도 돼요" 카피로 의미 보강.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '건너뛰기',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.lg,
                    fullWidth: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('등록 완료 (알람 없음) → drawer에서 확인'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: '완료',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.lg,
                    fullWidth: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('등록 완료 + 알람 1개 설정')),
                      );
                    },
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: i < current ? AppColors.primary : AppColors.borderHairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTypography.labelStrong);
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.close, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _AddTimeChip extends StatelessWidget {
  const _AddTimeChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHairline, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 16, color: AppColors.textMuted),
            SizedBox(width: 4),
            Text('시각 추가', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderHairline, width: selected ? 1.2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textFaint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DropdownLike extends StatelessWidget {
  const _DropdownLike({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: AppTypography.bodyMedium),
          const Icon(Icons.expand_more, color: AppColors.textFaint),
        ],
      ),
    );
  }
}
