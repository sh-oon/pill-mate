import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../app_buttons.dart';
import '../category_chip.dart';
import '../pill_icon.dart';

/// `rSh` — 놓친 복용 기록 수정 bottom sheet.
///
/// 호출: `await EditRecordSheet.show(context, ...)` → 사용자 선택 enum 반환.
enum EditRecordChoice { keep, markTaken }

class EditRecordSheet extends StatelessWidget {
  const EditRecordSheet._({
    required this.medName,
    required this.category,
    required this.time,
    required this.yesterday,
  });

  final String medName;
  final String category;
  final String time;
  final bool yesterday;

  static Future<EditRecordChoice?> show(
    BuildContext context, {
    required String medName,
    required String category,
    required String time,
    bool yesterday = false,
  }) {
    return showModalBottomSheet<EditRecordChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x80141428),
      builder: (_) => EditRecordSheet._(
        medName: medName,
        category: category,
        time: time,
        yesterday: yesterday,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              yesterday: yesterday,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            _MedInfoCard(
              medName: medName,
              category: category,
              time: time,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '그대로 둘게요',
                    variant: AppButtonVariant.primaryTint,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context)
                        .pop(EditRecordChoice.keep),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: '먹었던 걸로',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context)
                        .pop(EditRecordChoice.markTaken),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.medName,
    required this.yesterday,
    required this.onClose,
  });

  final String medName;
  final bool yesterday;
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
                '$medName을(를) ${yesterday ? '어제 ' : ''}드셨나요?',
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
  });

  final String medName;
  final String category;
  final String time;

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
                  '$time · 놓침으로 표시됨',
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

