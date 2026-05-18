import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../app_buttons.dart';
import '../med_pill_svg.dart';

/// 번들 알림 한 행의 데이터.
class BundleMed {
  const BundleMed({required this.name, required this.quantity});
  final String name;
  final String quantity;
}

/// `rNB` — 같은 시각 묶음 알림 (상단 anchored 카드).
///
/// 시안의 .nt는 상단에서 내려오는 알림 카드. Flutter는 showGeneralDialog +
/// 슬라이드 다운 transition으로 표현.
class BundleNotificationSheet extends StatefulWidget {
  const BundleNotificationSheet._({required this.time, required this.meds});

  final String time;
  final List<BundleMed> meds;

  static Future<void> show(
    BuildContext context, {
    required String time,
    required List<BundleMed> meds,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '알림 닫기',
      barrierColor: const Color(0x80141428),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => BundleNotificationSheet._(
        time: time,
        meds: meds,
      ),
      transitionBuilder: (_, anim, _, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  @override
  State<BundleNotificationSheet> createState() =>
      _BundleNotificationSheetState();
}

class _BundleNotificationSheetState extends State<BundleNotificationSheet> {
  late final List<bool> _checked =
      List.filled(widget.meds.length, false, growable: false);

  static const _appIconSvg = '''
<svg viewBox="0 0 120 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="20" y="20" width="80" height="120" rx="40" fill="white"/>
  <path d="M 20 80 L 100 80 L 100 100 A 40 40 0 0 1 60 140 A 40 40 0 0 1 20 100 Z" fill="#4661F2"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(time: widget.time, medsCount: widget.meds.length),
                  const SizedBox(height: 10),
                  _BundleList(
                    meds: widget.meds,
                    checked: _checked,
                    onToggle: (i) =>
                        setState(() => _checked[i] = !_checked[i]),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: '전부 먹었어요',
                          fullWidth: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: '1시간 뒤에',
                          variant: AppButtonVariant.primaryTint,
                          fullWidth: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.time, required this.medsCount});
  final String time;
  final int medsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgPicture.string(
            _BundleNotificationSheetState._appIconSvg,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'PillMate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textFaint,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$time 복용 시간 · $medsCount개',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '한 번에 챙기거나 하나씩 체크하세요',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BundleList extends StatelessWidget {
  const _BundleList({
    required this.meds,
    required this.checked,
    required this.onToggle,
  });

  final List<BundleMed> meds;
  final List<bool> checked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < meds.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.borderHairline),
            _Item(
              med: meds[i],
              checked: checked[i],
              onTap: () => onToggle(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.med,
    required this.checked,
    required this.onTap,
  });

  final BundleMed med;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: MedPillSvg(name: med.name, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                med.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.calendarCompleted : null,
                border: checked
                    ? null
                    : Border.all(color: const Color(0xFFC7CAD2), width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

