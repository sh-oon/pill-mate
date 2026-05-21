import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_buttons.dart';
import '../core/widgets/med_pill_svg.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — tracked detail 화면.
///
/// 알람 0개일 때 prominent "알람 추가" CTA. 알람 있을 때는 schedule 리스트.
class MockupTrackedDetail extends StatefulWidget {
  const MockupTrackedDetail({super.key});

  @override
  State<MockupTrackedDetail> createState() => _MockupTrackedDetailState();
}

class _MockupTrackedDetailState extends State<MockupTrackedDetail> {
  bool _hasAlarm = false;

  @override
  Widget build(BuildContext context) {
    return MockupScaffold(
      label: 'Phase 3 · Tracked detail (알람 추가 CTA)',
      child: Column(
        children: [
          // 토글 (mockup 전용 — 알람 유무 미리보기).
          Container(
            color: AppColors.surfaceMuted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('mockup 토글:', style: AppTypography.bodySmall),
                const Spacer(),
                Switch(
                  value: _hasAlarm,
                  onChanged: (v) => setState(() => _hasAlarm = v),
                ),
                const SizedBox(width: 6),
                Text(
                  _hasAlarm ? '알람 있음' : '알람 없음',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                _Header(),
                const SizedBox(height: 20),
                if (!_hasAlarm) _NoAlarmCta(onAdd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알람 추가 sheet 열림 → Step 3 화면 재사용')),
                  );
                }),
                if (_hasAlarm) _AlarmList(),
                const SizedBox(height: 24),
                _MetaSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const MedPillSvg(name: '유산균', size: 52),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('유산균', style: AppTypography.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successTint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'seed',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '영양제 · 100억 · Probiotics',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoAlarmCta extends StatelessWidget {
  const _NoAlarmCta({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.alarm, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('알람이 설정되지 않았어요', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '복용 시간을 등록하면 잊지 않게 도와드릴게요.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: '알람 추가',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.md,
            fullWidth: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _AlarmList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('알람', style: AppTypography.labelStrong),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '2',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: Text('추가', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AlarmRow(time: '08:00', repeat: '매일'),
        const SizedBox(height: 8),
        _AlarmRow(time: '20:00', repeat: '매일'),
      ],
    );
  }
}

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({required this.time, required this.repeat});
  final String time;
  final String repeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(time, style: AppTypography.titleMedium),
          const SizedBox(width: 10),
          Text(repeat, style: AppTypography.bodySmall),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('정보', style: AppTypography.labelStrong),
        const SizedBox(height: 8),
        _MetaRow(label: '카테고리', value: '영양제'),
        _MetaRow(label: '복용량', value: '100억 · 1캡슐'),
        _MetaRow(label: '메모', value: '저녁 식후'),
        _MetaRow(label: '복용 기간', value: '2026.05.21 ~ 무기한'),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
