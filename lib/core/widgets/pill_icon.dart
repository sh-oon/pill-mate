import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'med_pill_svg.dart';

/// 44×44 라운드 사각형(radius 14, bg `background`) 안에 약 아이콘 배치.
///
/// 두 가지 사용 모드:
/// - [medName] 지정: `MedPillSvg`로 시안 SVG 렌더.
/// - [color]/[letter] 지정: 단순 원형 + 선택적 글자 (시안에 없는 약 placeholder).
class PillIcon extends StatelessWidget {
  const PillIcon.svg({super.key, required String this.medName, this.size = 44})
      : color = null,
        letter = null;

  const PillIcon.flat({
    super.key,
    required Color this.color,
    this.letter,
    this.size = 44,
  }) : medName = null;

  final String? medName;
  final Color? color;
  final String? letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: medName != null
          ? MedPillSvg(name: medName!, size: size - 8)
          : Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: letter == null
                  ? null
                  : Text(
                      letter!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
    );
  }
}
