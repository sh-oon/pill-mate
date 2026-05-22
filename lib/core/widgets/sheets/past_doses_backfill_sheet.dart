import 'package:flutter/material.dart';

import '../../../features/medication/presentation/add/past_dose_slot.dart';
import '../../theme/app_colors.dart';
import '../app_buttons.dart';

/// 신규 등록/시각 추가 직후, 오늘 이미 지나간 시각에 대해
/// "이미 챙기셨나요?"를 묻는 bottom sheet.
///
/// caller(`medication_add_flow._maybeBackfillTodayPast`)가 후보 슬롯을 사전
/// 필터(오늘 + scheduledAt < now + isScheduleActiveOn + IntakeLog 부재)해
/// 전달. 시트는 선택만 담당 — DB write는 caller가 `IntakeRepository.markTaken`
/// 으로 일괄 처리.
///
/// 반환:
///   - `Set<int>`: 선택된 [slots] 인덱스
///   - `null`   : barrier dismiss / swipe down
///   - 빈 `Set` : "건너뛰기" 또는 아무것도 안 고르고 "기록할게요"
///
/// caller는 `null`과 빈 Set을 동등 처리(어차피 mark 호출 0회).
class PastDosesBackfillSheet extends StatefulWidget {
  const PastDosesBackfillSheet._({
    required this.slots,
    required this.medName,
    required this.quantityLabel,
  });

  final List<PastDoseSlot> slots;
  final String medName;
  final String quantityLabel;

  static Future<Set<int>?> show(
    BuildContext context, {
    required List<PastDoseSlot> slots,
    required String medName,
    required String quantityLabel,
  }) {
    return showModalBottomSheet<Set<int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x80141428),
      builder: (_) => PastDosesBackfillSheet._(
        slots: slots,
        medName: medName,
        quantityLabel: quantityLabel,
      ),
    );
  }

  @override
  State<PastDosesBackfillSheet> createState() => _PastDosesBackfillSheetState();
}

class _PastDosesBackfillSheetState extends State<PastDosesBackfillSheet> {
  final Set<int> _selected = <int>{};

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
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
            // drag handle
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
              medName: widget.medName,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            _SlotList(
              slots: widget.slots,
              quantityLabel: widget.quantityLabel,
              selected: _selected,
              onToggle: _toggle,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '건너뛰기',
                    variant: AppButtonVariant.primaryTint,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pop(const <int>{}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: '기록할게요',
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pop(Set<int>.from(_selected)),
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
  const _Header({required this.medName, required this.onClose});

  final String medName;
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
                '오늘 이미 챙기셨나요?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$medName 등록 전 시각이 있어요',
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

class _SlotList extends StatelessWidget {
  const _SlotList({
    required this.slots,
    required this.quantityLabel,
    required this.selected,
    required this.onToggle,
  });

  final List<PastDoseSlot> slots;
  final String quantityLabel;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.border),
            _SlotRow(
              time: slots[i].timeOfDay,
              quantity: quantityLabel,
              checked: selected.contains(i),
              onTap: () => onToggle(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.time,
    required this.quantity,
    required this.checked,
    required this.onTap,
  });

  final String time;
  final String quantity;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Checkbox(checked: checked),
            const SizedBox(width: 12),
            Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              quantity,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}
