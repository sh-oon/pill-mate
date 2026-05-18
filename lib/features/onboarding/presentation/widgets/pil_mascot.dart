import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 필 마스코트.
/// SVG 원본 비율 120:160 (3:4).
class PilMascot extends StatelessWidget {
  const PilMascot({super.key, this.size = 120, this.semanticLabel = '필 마스코트'});

  final double size;
  final String semanticLabel;

  static const String _assetPath = 'assets/onboarding/pil.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size * (160 / 120),
      semanticsLabel: semanticLabel,
    );
  }
}
