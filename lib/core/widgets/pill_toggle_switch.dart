import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.tg` 커스텀 토글 — primary on / grey off.
///
/// 시안 사양: 44×26 트랙, 22×22 노브, 라운드 풀(track radius 13).
class PillToggleSwitch extends StatelessWidget {
  const PillToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _w = 44.0;
  static const _h = 26.0;
  static const _knob = 22.0;
  static const _pad = 2.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: _w,
          height: _h,
          padding: const EdgeInsets.all(_pad),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.borderHairline,
            borderRadius: BorderRadius.circular(_h / 2),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x29000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
