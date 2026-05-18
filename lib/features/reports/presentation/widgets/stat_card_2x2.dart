import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `.sgc` 단일 카드 — 상단(아이콘+라벨) + 하단 큰 카운트.
class StatCardSpec {
  const StatCardSpec({
    required this.icon,
    required this.label,
    required this.count,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final int count;
  final StatTone tone;
}

enum StatTone { completed, scheduled, missed, total }

extension on StatTone {
  Color get tint => switch (this) {
        StatTone.completed => AppColors.successTint,
        StatTone.scheduled => AppColors.primaryTint,
        StatTone.missed => AppColors.missedTint,
        StatTone.total => AppColors.border,
      };
  Color get fg => switch (this) {
        StatTone.completed => AppColors.success,
        StatTone.scheduled => AppColors.primary,
        StatTone.missed => AppColors.missed,
        StatTone.total => AppColors.textMuted,
      };
  Color get countColor => switch (this) {
        StatTone.completed => AppColors.success,
        StatTone.scheduled => AppColors.primary,
        StatTone.missed => AppColors.missed,
        StatTone.total => AppColors.textStrong,
      };
}

/// `.scs-grid` — 2×2 격자 통계 카드.
class StatCard2x2 extends StatelessWidget {
  const StatCard2x2({super.key, required this.cards});

  final List<StatCardSpec> cards;

  @override
  Widget build(BuildContext context) {
    assert(cards.length == 4, 'StatCard2x2는 4개 셀 필요');
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Card(spec: cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _Card(spec: cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Card(spec: cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _Card(spec: cards[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.spec});
  final StatCardSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: spec.tone.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, size: 20, color: spec.tone.fg),
              ),
              const SizedBox(width: 8),
              Text(
                spec.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${spec.count}개',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: spec.tone.countColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
