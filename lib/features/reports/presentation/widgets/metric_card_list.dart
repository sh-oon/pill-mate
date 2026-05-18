import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum MetricTone { blue, purple, green }

extension on MetricTone {
  Color get tint => switch (this) {
        MetricTone.blue => AppColors.primaryTint,
        MetricTone.purple => AppColors.accentPurpleTint,
        MetricTone.green => AppColors.successTint,
      };
  Color get fg => switch (this) {
        MetricTone.blue => AppColors.primary,
        MetricTone.purple => AppColors.accentPurple,
        MetricTone.green => AppColors.success,
      };
}

class MetricRowSpec {
  const MetricRowSpec({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final String value;
  final MetricTone tone;
}

/// `.scs2` 흰 카드 한 박스에 여러 `.stc2` row가 hairline divider로 분리.
class MetricCardList extends StatelessWidget {
  const MetricCardList({super.key, required this.rows});

  final List<MetricRowSpec> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.border),
              _Row(spec: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.spec});
  final MetricRowSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: spec.tone.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(spec.icon, size: 22, color: spec.tone.fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  spec.sublabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            spec.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: spec.tone.fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
