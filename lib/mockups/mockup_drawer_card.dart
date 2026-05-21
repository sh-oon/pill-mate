import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/med_pill_svg.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — drawer 카드 알람 유무 시각적 구분.
///
/// 알람 ON: alarm_on 아이콘 + primary 색상, 다음 복용 시각 표시.
/// 알람 OFF: alarm_off 아이콘 + muted, "알람 없음" 라벨.
class MockupDrawerCard extends StatelessWidget {
  const MockupDrawerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupScaffold(
      label: 'Phase 3 · 약 서랍 카드 (알람 유무)',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('알람 있음', style: AppTypography.labelStrong),
          const SizedBox(height: 10),
          _Card(
            name: '비타민D',
            meta: '영양제 · 1000 IU · 오늘 1회',
            hasAlarm: true,
            nextTime: '오후 8:00',
            isSeed: true,
          ),
          const SizedBox(height: 10),
          _Card(
            name: '오메가3',
            meta: '영양제 · 1000 mg · 매일 1회',
            hasAlarm: true,
            nextTime: '아침 9:00',
            isSeed: true,
          ),
          const SizedBox(height: 24),
          Text('알람 없음', style: AppTypography.labelStrong),
          const SizedBox(height: 6),
          Text(
            'tracked만 등록한 항목 — drawer에서만 표시',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          _Card(
            name: '유산균',
            meta: '영양제 · 100억 · 알람 미설정',
            hasAlarm: false,
            isSeed: true,
          ),
          const SizedBox(height: 10),
          _Card(
            name: '내가 추가한 약',
            meta: '약 · 직접 입력',
            hasAlarm: false,
            isSeed: false,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '홈은 알람 있는 약만 표시 — 알람 없는 항목은 여기 drawer에서만 관리.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
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

class _Card extends StatelessWidget {
  const _Card({
    required this.name,
    required this.meta,
    required this.hasAlarm,
    this.nextTime,
    this.isSeed = false,
  });

  final String name;
  final String meta;
  final bool hasAlarm;
  final String? nextTime;
  final bool isSeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: MedPillSvg(name: name, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: AppTypography.titleMedium, overflow: TextOverflow.ellipsis)),
                    if (isSeed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successTint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('seed', style: AppTypography.bodySmall.copyWith(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // 알람 상태 배지.
          if (hasAlarm)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.alarm_on, color: AppColors.primary, size: 22),
                if (nextTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    nextTime!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            )
          else
            const Icon(Icons.alarm_off, color: AppColors.textFaint, size: 22),
        ],
      ),
    );
  }
}
