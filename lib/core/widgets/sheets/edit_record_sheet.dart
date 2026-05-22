import 'package:flutter/material.dart';

import '../../database/tables/intake_logs.dart';
import '../../theme/app_colors.dart';
import '../app_buttons.dart';
import '../category_chip.dart';
import '../pill_icon.dart';

/// `rSh` — 복용 기록 수정 bottom sheet.
///
/// 호출: `await EditRecordSheet.show(context, ...)` → 사용자 선택 enum 반환.
///
/// v2 (calendar-dose-edit): `allowMissed`/`currentStatus`/`dateLabel` 추가로
/// 양방향 toggle(taken↔missed) 지원. 기존 호출자는 default 값으로 그대로 동작.
enum EditRecordChoice { keep, markTaken, markMissed }

class EditRecordSheet extends StatelessWidget {
  const EditRecordSheet._({
    required this.medName,
    required this.category,
    required this.time,
    required this.dateLabel,
    required this.currentStatus,
    required this.allowMissed,
  });

  final String medName;
  final String category;
  final String time;
  final String dateLabel;
  final IntakeStatus? currentStatus;
  final bool allowMissed;

  /// [dateLabel]: "오늘"/"어제"/"3일 전" 등 (caller가 계산). null이면 [yesterday]
  ///   기반 fallback("어제"/"오늘") 사용 — 기존 호출자 호환.
  /// [currentStatus]: 액션 row 라벨 강조 분기에 사용. null이면 기존 missed 가정 톤.
  /// [allowMissed]: true → "놓침으로 표시"/"놓침으로 수정" 액션 노출 (Calendar/Home v2).
  static Future<EditRecordChoice?> show(
    BuildContext context, {
    required String medName,
    required String category,
    required String time,
    @Deprecated('Use dateLabel') bool yesterday = false,
    String? dateLabel,
    IntakeStatus? currentStatus,
    bool allowMissed = false,
  }) {
    final resolvedLabel = dateLabel ?? (yesterday ? '어제' : '오늘');
    return showModalBottomSheet<EditRecordChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x80141428),
      builder: (_) => EditRecordSheet._(
        medName: medName,
        category: category,
        time: time,
        dateLabel: resolvedLabel,
        currentStatus: currentStatus,
        allowMissed: allowMissed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = _resolveLeftAction(currentStatus, allowMissed);
    final right = _resolveRightAction(currentStatus, allowMissed);
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // .shh 핸들
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderHairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            _Header(
              medName: medName,
              dateLabel: dateLabel,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            _MedInfoCard(
              medName: medName,
              category: category,
              time: time,
              currentStatus: currentStatus,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: left.label,
                    variant: left.variant,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pop(left.choice),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: right.label,
                    variant: right.variant,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pop(right.choice),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.label,
    required this.variant,
    required this.choice,
  });
  final String label;
  final AppButtonVariant variant;
  final EditRecordChoice choice;
}

/// §5.1 표 — taken일 때만 좌측이 markMissed로 변하고, 나머지는 keep.
_ActionSpec _resolveLeftAction(IntakeStatus? st, bool allowMissed) {
  if (!allowMissed) {
    return const _ActionSpec(
      label: '그대로 둘게요',
      variant: AppButtonVariant.primaryTint,
      choice: EditRecordChoice.keep,
    );
  }
  switch (st) {
    case IntakeStatus.taken:
      return const _ActionSpec(
        label: '놓침으로 수정',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.markMissed,
      );
    case IntakeStatus.missed:
    case null:
      return const _ActionSpec(
        label: '그대로 둘게요',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.keep,
      );
    case IntakeStatus.pending:
    case IntakeStatus.skipped:
      return const _ActionSpec(
        label: '놓침으로 표시',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.markMissed,
      );
  }
}

_ActionSpec _resolveRightAction(IntakeStatus? st, bool allowMissed) {
  if (allowMissed && st == IntakeStatus.taken) {
    return const _ActionSpec(
      label: '그대로 둘게요',
      variant: AppButtonVariant.primary,
      choice: EditRecordChoice.keep,
    );
  }
  return const _ActionSpec(
    label: '이미 복용했어요',
    variant: AppButtonVariant.primary,
    choice: EditRecordChoice.markTaken,
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.medName,
    required this.dateLabel,
    required this.onClose,
  });

  final String medName;
  final String dateLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '기록 수정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$medName을(를) $dateLabel 드셨나요?',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.close, size: 22, color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }
}

class _MedInfoCard extends StatelessWidget {
  const _MedInfoCard({
    required this.medName,
    required this.category,
    required this.time,
    required this.currentStatus,
  });

  final String medName;
  final String category;
  final String time;
  final IntakeStatus? currentStatus;

  String get _statusLabel {
    switch (currentStatus) {
      case IntakeStatus.taken:
        return '이미 복용으로 표시됨';
      case IntakeStatus.missed:
        return '놓침으로 표시됨';
      case IntakeStatus.pending:
        return '예정됨';
      case IntakeStatus.skipped:
        return '건너뜀으로 표시됨';
      case null:
        return '놓침으로 표시됨'; // 기존 호출자(Home v1) 호환 fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          PillIcon.svg(medName: medName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        medName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CategoryChip.fromCode(category),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$time · $_statusLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
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
