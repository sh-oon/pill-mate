import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 약/영양제 이름 → 시안 SVG 매핑 (`PillMate.html`의 `P()` 함수 1:1 포팅).
///
/// 매핑 없는 이름은 회색 기본 원형으로 fallback.
class MedPillSvg extends StatelessWidget {
  const MedPillSvg({super.key, required this.name, this.size = 36});

  final String name;
  final double size;

  static const String _default =
      '<svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="14" fill="#C7CAD2"/></svg>';

  static const Map<String, String> _svgByName = {
    '종합비타민':
        '<svg viewBox="0 0 60 60"><ellipse cx="30" cy="30" rx="22" ry="13" fill="#FFD568" stroke="#E8B843" stroke-width="0.8"/><ellipse cx="30" cy="26" rx="16" ry="2.5" fill="#FFE69E" opacity="0.7"/></svg>',
    '유산균':
        '<svg viewBox="0 0 60 60"><rect x="6" y="20" width="48" height="20" rx="10" fill="#4D88FF" stroke="#3068E0" stroke-width="0.8"/><rect x="6" y="20" width="24" height="20" rx="10" fill="#92B6FF"/></svg>',
    '오메가3':
        '<svg viewBox="0 0 60 60"><g transform="rotate(-15 30 30)"><ellipse cx="30" cy="30" rx="18" ry="10" fill="#FFB52E" stroke="#E89A12" stroke-width="0.8"/><ellipse cx="26" cy="26" rx="9" ry="2" fill="#FFD068" opacity="0.7"/></g></svg>',
    '오메가-3':
        '<svg viewBox="0 0 60 60"><g transform="rotate(-15 30 30)"><ellipse cx="30" cy="30" rx="18" ry="10" fill="#FFB52E" stroke="#E89A12" stroke-width="0.8"/><ellipse cx="26" cy="26" rx="9" ry="2" fill="#FFD068" opacity="0.7"/></g></svg>',
    '마그네슘':
        '<svg viewBox="0 0 60 60"><ellipse cx="30" cy="30" rx="18" ry="13" fill="#B19DFB" stroke="#967DEB" stroke-width="0.8"/><line x1="14" y1="30" x2="46" y2="30" stroke="#967DEB" stroke-width="1"/></svg>',
    '비타민D':
        '<svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="16" fill="#FF85A1" stroke="#E66A88" stroke-width="0.8"/><text x="30" y="36" font-size="15" font-weight="800" fill="white" text-anchor="middle">D</text></svg>',
    '감기약':
        '<svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="16" fill="#E8EAF0" stroke="#C7CAD2" stroke-width="0.8"/><line x1="14" y1="30" x2="46" y2="30" stroke="#C7CAD2" stroke-width="1"/></svg>',
    '알레르기 약':
        '<svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="16" fill="#FFB3B3" stroke="#E89090" stroke-width="0.8"/></svg>',
  };

  static String svgFor(String name) => _svgByName[name] ?? _default;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svgFor(name),
        fit: BoxFit.contain,
      ),
    );
  }
}
